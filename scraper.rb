require "icon_scraper"

IconScraper.rest_xml(
  "https://apptracking.northsydney.nsw.gov.au/Pages/XC.Track/SearchApplication.aspx",
  "d=last14days&k=LodgementDate&o=xml"
)
