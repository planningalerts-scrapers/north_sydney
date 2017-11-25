require 'scraperwiki'
require 'mechanize'

case ENV['MORPH_PERIOD']
  when 'lastmonth'
  	period = "lastmonth"
  when 'thismonth'
  	period = "thismonth"
  else
    period = "thisweek"
    ENV['MORPH_PERIOD'] = 'thisweek'
end
puts "Getting data in `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

base_url = 'http://masterview.northsydney.nsw.gov.au/Pages/XC.Track/SearchApplication.aspx'
starting_url =  base_url + '?d=' + period + '&k=LodgementDate&'
comment_url = 'mailto:council@northsydney.nsw.gov.au'

def clean_whitespace(a)
  a.gsub("\r", ' ').gsub("\n", ' ').squeeze(" ").strip
end

agent = Mechanize.new

# Jump through bollocks agree screen
page = agent.get(starting_url)
puts "Agreeing"
page = page.forms.first.submit(page.forms.first.button_with(:value => "I Agree"))
page = agent.get(starting_url + "&o=xml")

# Explicitly interpret as XML
page = Nokogiri::XML(page.content)

raise "Can't find any <Application> elements" unless page.search('Application').length > 0

page.search('Application').each do |application|
  council_reference = clean_whitespace(application.at("ReferenceNumber").inner_text)

  application_id = clean_whitespace(application.at("ApplicationId").inner_text.strip)
  info_url = "#{base_url}?id=#{application_id}"

  unless application.at("Line1")
    puts "Skipping due to lack of address for #{council_reference}"
    next
  end

  address = clean_whitespace(application.at("Line1").inner_text)
  if !application.at('Line2').inner_text.empty?
    address += ", " + clean_whitespace(application.at("Line2").inner_text)
  end

  record = {
    "council_reference" => council_reference,
    "description" => clean_whitespace(application.at("ApplicationDetails").inner_text),
    "date_received" => Date.parse(application.at("LodgementDate").inner_text).to_s,
    "address" => address,
    "date_scraped" => Date.today.to_s,
    "info_url" => info_url,
    "comment_url" => comment_url,
  }

    if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
      puts "Saving record " + record['council_reference'] + " - " + record['address']
#       puts record
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
      puts "Skipping already saved record " + record['council_reference']
    end
end
