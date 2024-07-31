
// simple program to dump the contents of a mmdb file

package main

import (
	"flag"
	"fmt"
	"log"

	"github.com/oschwald/maxminddb-golang"
)

func main() {
	// Define command-line flag for the MMDB file
	dbFile := flag.String("db", "", "Path to the MMDB file")
	flag.Parse()

	// Check if the MMDB file is provided
	if *dbFile == "" {
		log.Fatal("Please provide the path to the MMDB file using the -db flag.")
	}

	// Open the MMDB file
	db, err := maxminddb.Open(*dbFile)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

        // Print database metadata
	printDBMetadata(db)

	// Iterate over all networks in the database
	iter := db.Networks()
	for iter.Next() {
		var record interface{}
		subnet, err := iter.Network(&record)
		if err != nil {
			log.Fatal(err)
		}

		// Print the subnet and associated data
		fmt.Printf("Network: %s\nData: %v\n\n", subnet, record)
	}

	if iter.Err() != nil {
		log.Fatal(iter.Err())
	}
}

// Function to print the database metadata
func printDBMetadata(db *maxminddb.Reader) {
	meta := db.Metadata

	fmt.Printf("Database Type: %s\n", meta.DatabaseType)
	fmt.Printf("Description: %v\n", meta.Description)
	fmt.Printf("IP Version: %d\n", meta.IPVersion)
	fmt.Printf("Node Count: %d\n", meta.NodeCount)
	fmt.Printf("Record Size: %d\n", meta.RecordSize)
}


