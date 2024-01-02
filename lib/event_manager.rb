require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

time = Time.new

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_numbers(number)
    number.gsub!(/[.,\-\/() ) ]/, '')
    if number.length == 10
        number
    elsif number.length == 11 && number[0] == 1
        number[1..10]
    elsif number.length == 11 && number[0] != 1
        number = nil
    else
        number = nil
    end
end

def registration_date_time_peak(date)
  DateTime.strptime(date,"%m/%d/%y %H:%M")
end

def most_frequent(array_given)
  counts = array_given.reduce(Hash.new(0)) do |hash, element|
    hash[element] += 1
    hash
  end
  counts.max_by { |_, element| element}
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours = []
days = []
index = 0
days_in_week = { 0=>"Sunday", 1=>"Monday", 2=>"Tuesday", 3=>"Wednesday", 4=>"Thursday", 5=>"Friday", 6=>"Saturday"}
contents.each do |row|
  id = row[0]
  date_time = registration_date_time_peak(row[:regdate])
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  hours[index] = date_time.hour
  days[index] = date_time.wday
  index += 1
  #puts date_time
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id,form_letter)
end

# puts hours
# puts ""
# puts days
most_frequent_hour = most_frequent(hours)
most_frequent_day = most_frequent(days)

puts "The most frequent hour is #{most_frequent_hour[0]} with #{most_frequent_hour[1]} occurrences."
puts "The most frequent day is #{days_in_week[most_frequent_day[0]]} with #{most_frequent_day[1]} occurrences."