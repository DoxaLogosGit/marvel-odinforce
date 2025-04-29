package main

import "core:fmt"
import "core:math"
import "core:time"
import "core:strconv"
import "core:strings"
import "core:encoding/xml"
import "http/client"

BASE_URL: string = "http://www.boardgamegeek.com/xmlapi2/"
PLAYS: string = "plays?"
ENTRIES_PER_PAGE: int = 100
MARVEL_CHAMPIONS_ID: string = "285774"

// Function to determine number of pages
determine_number_of_pages :: proc(xml_data: ^string) -> int {
    doc, err := xml.parse_string(xml_data^)
    if err != nil {
        fmt.println("Failed to parse XML:", err)
        return -1
    }

    //TODO: find correct parent_id
    total_str, ok := xml.find_attribute_val_by_key(doc,0,"total")
    if !ok {
        fmt.println("No total attribute found in XML.")
        return -1
    }

    entries := strconv.atof(total_str)

    pages := math.ceil(entries / f64(ENTRIES_PER_PAGE))
    return int(pages)
}

// Function to retrieve a play page
retrieve_play_page :: proc(user: string, page_num: string = "1") -> ^string {

    url := fmt.tprint(BASE_URL, PLAYS, "username=", user, "&id=", MARVEL_CHAMPIONS_ID, "&type=things&subtype=boardgame&page=", page_num)
    response, err := client.get(url)
    if err != nil {
        fmt.println("HTTP request failed:", err)
        return nil
    }

	body, allocation, berr := client.response_body(&response)
	if berr != nil {
		fmt.printf("Error retrieving response body: %s", berr)
		return nil
	}
	defer client.body_destroy(body, allocation)

    page : ^string 
    append(page,fmt.aprintf("%s",body))
    return page
}

// Main function to retrieve all play data
retrieve_play_data_from_bgg :: proc(user: string) -> ^string {

    first_page_data := retrieve_play_page(user)
    if first_page_data == nil {
        return nil
    }
    defer delete(first_page_data)


    pages := determine_number_of_pages(first_page_data)
    fmt.printf("Pages of data to retrieve: %d\n", pages)

    build_xml := strings.builder_make()
    strings.write_string(&build_xml, first_page_data^)

    for index in 2..=pages {
        fmt.printf("Retrieving page %d...\n", index)
        time.sleep(500 * time.Millisecond)

        page_str := strconv.itoa(index)
        page_data := retrieve_play_page(user, page_str)
        defer page_data
        if len(page_data) != 0 {
            strings.write_string(&build_xml, page_data)
        }

    }
    xml_data := strings.to_string(build_xml)
    strings.builder_destroy(&build_xml)

    return xml_data
}

main :: proc() {
    user := "your_bgg_username_here"
    play_data := retrieve_play_data_from_bgg(user)

    if play_data == nil {
        fmt.println("Failed to retrieve play data.")
    } else {
        fmt.printf("Successfully retrieved %d pages of data.\n", len(play_data))
    }
}

