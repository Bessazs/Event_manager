# puts File.exist? "event_attendees.csv"
# contents = File.read('event_attendees.csv')
# puts contents

# lines = File.readlines('event_attendees.csv')
# lines.each_with_index do |line,index|
#   next if index == 0
#   columns = line.split(",")
#   name = [columns[2]]
#   puts name
#   row_index += 1
# end

require "erb"
require "csv"
require "google/apis/civicinfo_v2"
require "time"
require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.delete!("^0-9")
  if phone_number.size == 11 && phone_number.start_with?("1")
    phone_number[1..-1]
  elsif phone_number.size == 10
    phone_number
  else
    "0000000000"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def find_hour(hour); end

puts "EventManager initialized."

contents = CSV.open(
  "lib/event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

hours = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  time = Time.strptime(row[:regdate], "%m/%d/%Y %k:%M")

  hours.push(time.hour)
  days.push(Date.new(time.day, time.month, time.year).wday)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts days.tally
puts hours.tally
