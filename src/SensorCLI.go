package main

import (
	"bufio"
	"bytes"
	"fmt"
	"strings"
	"time"
)

type tempData struct {
	HourMinute string
	theData    string
}

func main() {
	// data is embedded into the executable. Run "go-bindata data/" in the project folder and copy the go file
	csvfile, err := Asset("data/Data.csv")
	if err != nil {
		fmt.Println(err)
	}
	/*
		We're going to match the current hour and and minute
		with the value in an array, here we get the current time
		Format strings are weird in Go! 3:04 is magical
	*/
	dt := time.Now()
	hourMinute := dt.Format("3:04") + ":00"

	// Read the file by lines because each hourMinute is on its own line in the file
	scanner := bufio.NewScanner(bytes.NewReader(csvfile))
	scanner.Split(bufio.ScanLines)
	// Rebuilding the byte array as an array of strings split by line breaks
	var lines []string
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	for _, line := range lines {
		// for each line in the data file,
		// split the line with commas (CSV)
		s := strings.Split(line, ",")
		// Jamming this into a struc because it might make things easier later
		temp := tempData{
			HourMinute: s[0],
			theData:    s[1],
		}
		// Yep, didn't need the struc here, but it will pay off later, much later
		if temp.HourMinute == hourMinute {
			fmt.Println(temp.theData)
		}
	}
}
