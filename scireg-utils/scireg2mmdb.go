
// this program requires mmdbwriter from github.com/maxmind
// to install:
//    go mod init generate_mmdb
//    go get github.com/maxmind/mmdbwriter
// To build:
//    go build -o scireg2mmdb scireg2mmdb.go
// To run:
//    scireg2mmdb -i scireg.json -o scireg.mmdb


package main

import (
    "encoding/json"
    "flag"
    "fmt"
    "io/ioutil"
    "log"
    "net"
    "os"

    "github.com/maxmind/mmdbwriter"
    "github.com/maxmind/mmdbwriter/mmdbtype"
)

// Resource represents the structure of each resource entry in the JSON input.
type Resource struct {
    Subnet       string `json:"subnet"`
    Discipline   string `json:"discipline"`
    Latitude     string `json:"latitude"`
    Longitude    string `json:"longitude"`
    OrgName      string `json:"org_name"`
    OrgAbbr      string `json:"org_abbr"`
    ResourceName string `json:"resource_name"`
    Projects     string `json:"projects"`
}

// Resources represents the top-level structure of the JSON input.
type Resources struct {
// simple program to dump the contents of a mmdb file

    Resources []Resource `json:"resources"`
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

    // Read the JSON file
    jsonData, err := ioutil.ReadFile(*inputFile)
    if err != nil {
        log.Fatalf("Failed to read input file: %v", err)
    }
    // Print the raw JSON data for debugging
    // fmt.Printf("Raw JSON data: %s\n", string(jsonData))

    // Parse the JSON data into the Resources struct
    var resourcesData Resources
    err = json.Unmarshal(jsonData, &resourcesData)
    if err != nil {
        log.Fatalf("Failed to parse JSON: %v", err)
    }
    // Print the parsed data for debugging
    // fmt.Printf("Parsed resources data: %+v\n", resourcesData)

    // Create a new MMDB writer with specified options
    writer, err := mmdbwriter.New(mmdbwriter.Options{
        DatabaseType: "GeoLite2-City",
        RecordSize:   24,
    })
    if err != nil {
        log.Fatalf("Failed to create MMDB writer: %v", err)
    }
    // Counter for the number of records inserted
    var recordCount int

    // Iterate over the resources and insert data into the MMDB writer
    for _, resource := range resourcesData.Resources {
        // Parse the subnet from CIDR notation
        _, subnet, err := net.ParseCIDR(resource.Subnet)
        if err != nil {
            log.Fatalf("Failed to parse subnet: %v", err)
        }

        // Create a map of the data to be stored in the MMDB
        geoData := mmdbtype.Map{
            "discipline":    mmdbtype.String(resource.Discipline),
            "latitude":      mmdbtype.String(resource.Latitude),
            "longitude":     mmdbtype.String(resource.Longitude),
            "org_name":      mmdbtype.String(resource.OrgName),
            "org_abbr":      mmdbtype.String(resource.OrgAbbr),
            "resource_name": mmdbtype.String(resource.ResourceName),
            "projects":      mmdbtype.String(resource.Projects),
        }
        // Print the geoData for debugging
	fmt.Printf("Inserting data for subnet: %s\n", resource.Subnet)
	//fmt.Printf("geoData: %v\n", geoData)

        // Insert the data into the MMDB writer
        err = writer.Insert(subnet, geoData)
        if err != nil {
            log.Fatalf("Failed to insert data into MMDB: %v", err)
        }
	recordCount++
    }

    // Create the output MMDB file
    outputFileHandle, err := os.Create(*outputFile)
    if err != nil {
        log.Fatalf("Failed to create output file: %v", err)
    }
    defer outputFileHandle.Close()

    // Write the MMDB data to the output file
    _, err = writer.WriteTo(outputFileHandle)
    if err != nil {
        log.Fatalf("Failed to write MMDB file: %v", err)
    }

    // Print a success message
    fmt.Printf("MMDB file created successfully! Total records inserted: %d\n", recordCount)

}


