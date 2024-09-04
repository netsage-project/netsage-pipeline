
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
    "encoding/json"
    "flag"
    "fmt"
    "log"
    "net"
    "os"
    "strconv"
    "strings"
//    "io/ioutil"
    "github.com/maxmind/mmdbwriter"
    "github.com/maxmind/mmdbwriter/mmdbtype"
)

type AddressBlock struct {
	Addresses    []string `json:"addresses"`
	OrgName      string   `json:"org_name"`
	Discipline   string   `json:"discipline"`
	Latitude     string   `json:"latitude"`
	Longitude    string   `json:"longitude"`
	ResourceName string   `json:"resource_name"`
	ProjectName  string   `json:"project_name"`
	SciRegID     int      `json:"scireg_id"`
	ContactEmail string   `json:"contact_email"`
	LastUpdated  string   `json:"last_updated"`
}

func main() {
    // Define command-line flags for input and output files
       inputFile := flag.String("i", "", "Input JSON file")
       outputFile := flag.String("o", "", "Output MMDB file")
       flag.Parse()

    // Check if input and output files are provided
       if *inputFile == "" || *outputFile == "" {
           flag.Usage()
           os.Exit(1)
       }

	// Open and read the input JSON file
	file, err := os.Open(*inputFile)
	if err != nil {
		log.Fatalf("Failed to open input file: %v", err)
	}
	defer file.Close()

	// Parse JSON data
	var entries []AddressBlock
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&entries); err != nil {
		log.Fatalf("Failed to decode JSON: %v", err)
	}

	// Create an MMDB writer
	writer, err := mmdbwriter.New(mmdbwriter.Options{
            DatabaseType: "GeoLite2-City",
            Description: map[string]string{ "en": "Fake GeoIP2-City db for Science Registry"},
            RecordSize:   24,
	})
	if err != nil {
		log.Fatalf("Failed to create MMDB writer: %v", err)
	}
	recordCount := 0

	// Process each entry and add to MMDB
	for _, entry := range entries {

                // Convert Latitude and Longitude strings to float64
                lat, err := strconv.ParseFloat(strings.TrimSpace(entry.Latitude), 64)
                if err != nil {
                     log.Printf("Warning: Failed to parse Latitude: %v", err)
                     lat = 0.0 // Default value or handle accordingly
                }

                long, err := strconv.ParseFloat(strings.TrimSpace(entry.Longitude), 64)
                if err != nil {
                     log.Printf("Warning: Failed to parse Latitude: %v", err)
                     long = 0.0 // Default value or handle accordingly
                }

		for _, addr := range entry.Addresses {
			_, network, err := net.ParseCIDR(addr)
			if err != nil {
				log.Printf("Invalid CIDR %s: %v", addr, err)
				continue
			}

                        // Initialize jsonString
                        var jsonString string

                        // all of these fields get embedded to 'city'
                        jsonString = fmt.Sprintf(`{"discipline": "%s", "org_name": "%s", "resource": "%s", "project": "%s"}`,
                                entry.Discipline, entry.OrgName, entry.ResourceName, entry.ProjectName)

                        geoData := mmdbtype.Map{
                                "city": mmdbtype.Map{
                                        "names": mmdbtype.Map{
                                                "en": mmdbtype.String(jsonString),
                                        },
                                },
                                "location": mmdbtype.Map{
                                            "latitude":  mmdbtype.Float64(lat),
                                            "longitude": mmdbtype.Float64(long),
                                },
                        }

                        // Debug: Print the record data going into the MMDB
			//fmt.Printf("Inserting record for %s:\n", addr)
			//for k, v := range geoData {
		        //	fmt.Printf("  %s: %v\n", k, v)
			//}

			err = writer.Insert(network, geoData)
			if err != nil {
				log.Fatalf("Failed to insert record: %v", err)
			}
			recordCount++
		}

	}

	// Write the MMDB file
	out, err := os.Create(*outputFile)
	if err != nil {
		log.Fatalf("Failed to create output file: %v", err)
	}
	defer out.Close()

	_, err = writer.WriteTo(out)
	if err != nil {
		log.Fatalf("Failed to write MMDB: %v", err)
	}

	fmt.Printf("MMDB created successfully with %d records!\n", recordCount)

}


