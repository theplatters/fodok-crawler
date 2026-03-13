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

def generate_latex(rows, out_filename, formatter:)
  latex = group_by_year(rows, &formatter)
  File.write(out_filename, latex)
end

def by_year_formatter(year, rows, &item_format)
  subsection = "\\subsection*{#{year}}"

  items = rows.map do |row|
    item_format.call(row)
  end.join("\n")

  subsection + "
\\begin{enumerate}
#{items}
\\end{enumerate}\n"
end
