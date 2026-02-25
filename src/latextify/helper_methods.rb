def sanitize(string)
  string&.gsub(/([&%$#_{}^\\])/, '\\\\\1')&.gsub(/"(.+)"/, '\\glqq \1\\grqq{}')&.gsub(/ - /, ' -- ')
end

def group_by_year(items, &latextify)
  items.group_by { |row| row['Jahr'] }
       .map { |year, rows| latextify.call(year, rows) }
       .join
end
