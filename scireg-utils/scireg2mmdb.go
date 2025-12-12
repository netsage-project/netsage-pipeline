
// Based on this blog: https://blog.maxmind.com/2020/09/enriching-mmdb-files-with-your-own-data-using-go/
//
// this program requires mmdbwriter from github.com/maxmind
// to install:
//    type: 'make'
// or:
//    go mod init generate_mmdb
//    go get github.com/maxmind/mmdbwriter
// To build:
//    go build -o scireg2mmdb scireg2mmdb.go
// To run:
//    scireg2mmdb -i scireg.json -o scireg.mmdb
// To verify results:
//    dump_mmdb -db scireg.mmdb

package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/maxmind/mmdbwriter"
	"github.com/maxmind/mmdbwriter/mmdbtype"
)

type Entry struct {
	Addresses    []string `json:"addresses"`
	OrgName      string   `json:"org_name"`
	Discipline   string   `json:"discipline"`
	ResourceName string   `json:"resource_name"`
	ProjectName  string   `json:"project_name"`
	SciregID     int      `json:"scireg_id"`
	ContactEmail string   `json:"contact_email"`
	LastUpdated  string   `json:"last_updated"`
	Latitude     string   `json:"latitude"`
	Longitude    string   `json:"longitude"`
	Community    string   `json:"community"`
}

type CIDREntry struct {
	Network *net.IPNet
	Entry   Entry
	Lat     float64
	Long    float64
	Prefix  int
}

func main() {
	inputFile := flag.String("i", "", "Input JSON file")
	outputFile := flag.String("o", "", "Output MMDB file")
	flag.Parse()

	if *inputFile == "" || *outputFile == "" {
		flag.Usage()
		os.Exit(1)
	}

	file, err := os.Open(*inputFile)
	if err != nil {
		log.Fatalf("Failed to open input file: %v", err)
	}
	defer file.Close()

	decoder := json.NewDecoder(bufio.NewReader(file))
	var entries []Entry
	if err := decoder.Decode(&entries); err != nil {
		log.Fatal(err)
	}

	var cidrEntries []CIDREntry
	for _, entry := range entries {
		lat := parseFloat(entry.Latitude)
		long := parseFloat(entry.Longitude)

		for _, addr := range entry.Addresses {
			_, ipnet, err := net.ParseCIDR(addr)
			if err != nil {
				log.Fatalf("Invalid CIDR: %s", addr)
			}
			prefix, _ := ipnet.Mask.Size()
			cidrEntries = append(cidrEntries, CIDREntry{
				Network: ipnet,
				Entry:   entry,
				Lat:     lat,
				Long:    long,
				Prefix:  prefix,
			})
		}
	}

	// For any subnet smaller than /24 (prefix > 24), create an additional MMDB
	// entry:
	//   - IPv4: x.y.z.1/32 where x.y.z.* is the /24 containing the subnet
	//   - IPv6: <same /64 high bits>::1/128 for the /64 containing the subnet
	var extraEntries []CIDREntry
	for _, ce := range cidrEntries {
		ip := ce.Network.IP
		if ip == nil {
			continue
		}

		isV4 := ip.To4() != nil
		var hostIP net.IP
		var hostPrefix int

		if isV4 {
			// Only add a .1 entry for IPv4 prefixes > /24
			if ce.Prefix <= 24 {
				continue
			}
			ip4 := ip.To4()
			if ip4 == nil {
				continue
			}

                        // only generate the .1/32 entry if subnet starts with an IP > 1
                        if ip4[3] <= 1 {
                                continue
                        }
			// Parent /24 is ip4[0].ip4[1].ip4[2].0, but we want the .1 in that /24
			hostIP = net.IPv4(ip4[0], ip4[1], ip4[2], 1)
			hostPrefix = 32
		} else {
			// For IPv6, apply the same "smaller than /24" rule on prefix length:
			// any IPv6 prefix > /24 gets an extra ::1 in the containing /64.
			if ce.Prefix <= 24 || ce.Prefix >= 128 {
				continue
			}
			ip16 := ip.To16()
			if ip16 == nil {
				continue
			}
			host := make(net.IP, net.IPv6len)
			copy(host, ip16)
			// Keep upper 64 bits, zero the lower 63 bits, set the last bit to 1:
			// -> <same /64>::1
			for i := 8; i < 15; i++ {
				host[i] = 0
			}
			host[15] = 1
			hostIP = host
			hostPrefix = 128
		}

		hostCIDR := fmt.Sprintf("%s/%d", hostIP.String(), hostPrefix)
		_, hostNet, err := net.ParseCIDR(hostCIDR)
		if err != nil {
			log.Printf("Warning: could not parse host CIDR %s derived from %s: %v",
				hostCIDR, ce.Network.String(), err)
			continue
		}

		// Status message so you can see what is being created
		if isV4 {
			fmt.Printf("  Adding .1 host entry %s for subnet %s to match Globus logs \n",
				hostCIDR, ce.Network.String())
		} else {
			fmt.Printf("  Adding ::1 host entry %s for subnet %s to match Globus logs \n",
				hostCIDR, ce.Network.String())
		}

		extraEntries = append(extraEntries, CIDREntry{
			Network: hostNet,
			Entry:   ce.Entry,
			Lat:     ce.Lat,
			Long:    ce.Long,
			Prefix:  hostPrefix,
		})
	}

	// Append the extra .1 / ::1 host entries
	cidrEntries = append(cidrEntries, extraEntries...)

	// Sort CIDRs by specificity (less specific first, more specific last)
	sort.Slice(cidrEntries, func(i, j int) bool {
		return cidrEntries[i].Prefix < cidrEntries[j].Prefix
	})

	writer, err := mmdbwriter.New(mmdbwriter.Options{DatabaseType: "City", RecordSize: 24})
	if err != nil {
		log.Fatal(err)
	}

	// Map from CIDR string to set of communities (merged communities for contained ranges)
	merged := make(map[string]map[string]bool)

	for _, outer := range cidrEntries {
		community := outer.Entry.Community
		for _, inner := range cidrEntries {
			if outer.Network.Contains(inner.Network.IP) {
				key := inner.Network.String()
				if _, exists := merged[key]; !exists {
					merged[key] = make(map[string]bool)
				}
				merged[key][community] = true
			}
		}
	}

	for _, cidr := range cidrEntries {
		key := cidr.Network.String()
		communities := merged[key]
		var list []string
		for c := range communities {
			list = append(list, c)
		}
		sort.Strings(list)

		dataMap := map[string]interface{}{
			"discipline": cidr.Entry.Discipline,
			"org_name":   cidr.Entry.OrgName,
			"resource":   cidr.Entry.ResourceName,
			"project":    cidr.Entry.ProjectName,
			"community":  list,
		}
		jsonBytes, _ := json.Marshal(dataMap)

		geoData := mmdbtype.Map{
			"city": mmdbtype.Map{
				"names": mmdbtype.Map{
					"en": mmdbtype.String(jsonBytes),
				},
			},
			"location": mmdbtype.Map{
				"latitude":  mmdbtype.Float64(cidr.Lat),
				"longitude": mmdbtype.Float64(cidr.Long),
			},
		}

		err := writer.InsertFunc(cidr.Network, func(oldData mmdbtype.DataType) (mmdbtype.DataType, error) {
			return geoData, nil
		})
		if err != nil {
			log.Fatalf("Failed to insert %s: %v", cidr.Network.String(), err)
		}
	}

	f, err := os.Create(*outputFile)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	if _, err := writer.WriteTo(f); err != nil {
		log.Fatal(err)
	}

	fmt.Printf("MMDB file %s created successfully with %d records (including .1/::1 host entries)!\n",
		*outputFile, len(cidrEntries))
}

func parseFloat(s string) float64 {
	f, err := strconv.ParseFloat(strings.TrimSpace(s), 64)
	if err != nil {
		return 0.0
	}
	return f
}

