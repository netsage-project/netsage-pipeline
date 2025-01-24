
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
    "github.com/maxmind/mmdbwriter"
    "github.com/maxmind/mmdbwriter/mmdbtype"
)

type AddressBlock struct {
    Addresses    []string `json:"addresses"`
    OrgName      string   `json:"org_name"`
    Discipline   string   `json:"discipline"`
    Community    string   `json:"community"`
    Latitude     string   `json:"latitude"`
    Longitude    string   `json:"longitude"`
    ResourceName string   `json:"resource_name"`
    ProjectName  string   `json:"project_name"`
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

    var entries []AddressBlock
    decoder := json.NewDecoder(file)
    if err := decoder.Decode(&entries); err != nil {
        log.Fatalf("Failed to decode JSON: %v", err)
    }

    writer, err := mmdbwriter.New(mmdbwriter.Options{
        DatabaseType: "GeoLite2-City",
        Description: map[string]string{"en": "Fake GeoIP2-City db for Science Registry"},
        RecordSize:   24,
    })
    if err != nil {
        log.Fatalf("Failed to create MMDB writer: %v", err)
    }

    recordCount := 0

    for _, entry := range entries {
        // Print JSON content for reference
        entryJson, _ := json.Marshal(entry)

        lat, err := strconv.ParseFloat(strings.TrimSpace(entry.Latitude), 64)
        if err != nil {
            // log.Printf("No Latitude for entry: %s, setting to 0. ", entryJson)
            lat = 0.0
        }

        long, err := strconv.ParseFloat(strings.TrimSpace(entry.Longitude), 64)
        if err != nil {
            // log.Printf("No Longitude for entry: %s, setting to 0. ", entryJson)
            long = 0.0
        }

        for _, addr := range entry.Addresses {
            _, network, err := net.ParseCIDR(addr)
            if err != nil {
                log.Printf("Invalid CIDR %s for entry: %s, skipping. Error: %v", addr, entryJson, err)
                continue
            }

            jsonString := fmt.Sprintf(`{"discipline": "%s", "org_name": "%s", "resource": "%s", "project": "%s", "community": "%s"}`,
                entry.Discipline, entry.OrgName, entry.ResourceName, entry.ProjectName, entry.Community)

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

            if err = writer.Insert(network, geoData); err != nil {
                log.Printf("Error inserting record for network %s: %v\nEntry Data: %s", addr, err, entryJson)
                continue
            }
            recordCount++
        }
    }

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

