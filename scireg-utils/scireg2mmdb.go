
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
	Addresses     []string `json:"addresses"`
	OrgName       string   `json:"org_name"`
	Discipline    string   `json:"discipline"`
	ResourceName  string   `json:"resource_name"`
	ProjectName   string   `json:"project_name"`
	SciregID      int      `json:"scireg_id"`
	ContactEmail  string   `json:"contact_email"`
	LastUpdated   string   `json:"last_updated"`
	Latitude      string   `json:"latitude"`
	Longitude     string   `json:"longitude"`
	Community     string   `json:"community"`
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

      // Sort CIDRs by specificity (less specific first, more specific last)
      // mmdb seems to require this to return more specific first
	sort.Slice(cidrEntries, func(i, j int) bool {
		return cidrEntries[i].Prefix < cidrEntries[j].Prefix
	})

	writer, err := mmdbwriter.New(mmdbwriter.Options{DatabaseType: "City", RecordSize: 24})
	if err != nil {
		log.Fatal(err)
	}

	// Map from IP string to set of communities
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
			"org_name": cidr.Entry.OrgName,
			"resource": cidr.Entry.ResourceName,
			"project": cidr.Entry.ProjectName,
			"community": list,
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

        fmt.Printf("MMDB file %s created successfully with %d records!\n", *outputFile, len(cidrEntries))
}

func parseFloat(s string) float64 {
	f, err := strconv.ParseFloat(strings.TrimSpace(s), 64)
	if err != nil {
		return 0.0
	}
	return f
}


