# frozen_string_literal: true

def sanitize(string)
  string&.gsub(/([&%$#_{}^\\])/, '\\\\\1')&.gsub(/"(.+)"/, '\\glqq \1\\grqq{}')&.gsub(/ - /, ' -- ')
end

def group_by_type(&latextify)
  lambda do |items|
    items.group_by { |row| row['Jahr'] }
         .map { |year, rows| latextify.call(year, rows) }
         .join
  end
end

def group_by_year(&latextify)
  lambda do |items|
    items.group_by { |row| row['Jahr'] }
         .map { |year, rows| latextify.call(year, rows) }
         .join
  end
end

def extract_wp_number(str)
  match = str.match(/(?<=Nr\.\s)\d+/)
  match ? match[0].to_i : nil
end

def sort_descending(arr)
  arr.sort_by { |str| [-(extract_number(str) || -1), str] }
end

def generate_latex(rows, out_filename, formatter:)
  latex = group_by_year(&formatter).call(rows)
  File.write(out_filename, latex)
end

def in_2026?(row)
  row['Jahr'].to_i == 2026
end

def simple_formatter(group_by: nil, &item_format)
  lambda do |rows|
    items =
      if group_by
        rows
          .group_by(&group_by)
          .map { |key, group| item_format.call(key, group) }
      else
        rows
          .map { |row| item_format.call(row) }
      end

    "\\begin{enumerate}
#{items.join("\n")}
\\end{enumerate}\n"
  end
end

def by_year_formatter(formatter:)
  lambda do |year, rows|
    subsection = "\\subsection*{#{year}}\n"
    subsection + formatter.call(rows).to_s
  end
end

def group_formatter(group_by:, &item_format)
  lambda do |rows|
    rows
      .group_by(&group_by)
      .map { |key, group| item_format.call(key, group) }
      .join("\n")
  end
end
