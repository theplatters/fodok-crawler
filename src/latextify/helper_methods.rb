# frozen_string_literal: true

def sanitize(string)
  string&.gsub(/([&%$#_{}^\\])/, '\\\\\1')&.gsub(/"(.+)"/, '\\glqq \1\\grqq{}')&.gsub(/ - /, ' -- ')
end

def group_by_year(items, &latextify)
  items.group_by { |row| row['Jahr'] }
       .map { |year, rows| latextify.call(year, rows) }
       .join
end

def extract_wp_number(str)
  match = str.match(/(?<=Nr\.\s)\d+/)
  match ? match[0].to_i : nil
end

def sort_descending(arr)
  arr.sort_by { |str| [-(extract_number(str) || -1), str] }
end
