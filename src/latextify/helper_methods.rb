# frozen_string_literal: true

module Columns
  YEAR = 'Jahr'
  TITLE = 'Titel'
  NAME = 'Name'
  PERSONS = 'Personen'
  EXTERNAL_PERSON = 'Externe Person'
  START_DATE = 'Startdatum'
  PUBLICATION_DATE = 'Datum der Veröffentlichung'
  EVENT = 'Veranstaltung'
  TYPE = 'Übergeordneter Typ'
  PRODUCER = 'Produzent/Autor'
  MEDIA_HOUSE = 'Name Medienhaus/Outlet'
  MEDIA_FORMAT = 'Medienformat'
  APA_FORMAT = 'APA-Format'
  ROLE = 'Rollen der Mitwirkenden'
end

def sanitize(string)
  return nil unless string

  string
    .gsub(/([&%$#_{}^\\])/, '\\\\\1')
    .gsub(/"(.+)"/, '\\glqq \1\\grqq{}')
    .gsub(/ - /, ' -- ')
end

def extract_year_from_date(date_string)
  Date.parse(date_string).year
end

def group_by_year(&latextify)
  lambda do |items|
    items.group_by { |row| row['Jahr'] }
         .map { |year, rows| latextify.call(year, rows) }
         .join
  end
end

def format_date(date_string, format: '%d.%m.%Y')
  return '' if date_string.nil? || date_string.strip.empty?

  Date.parse(date_string).strftime(format)
end

def extract_wp_number(str)
  str[/(?<=Nr\.\s)\d+/]&.to_i
end

def generate_latex(rows, out_filename, formatter:, group_by_year: true)
  latex = group_by_year ? group_by_year(&formatter).call(rows) : formatter.call(rows)
  File.write(out_filename, latex)
end

def in_2026?(row)
  row['Jahr'].to_i == 2026
end

def simple_formatter(group_by: nil, &item_format)
  lambda do |rows|
    items = if group_by
              rows.group_by(&group_by).map { |key, group| item_format.call(key, group) }
            else
              rows.map { |row| item_format.call(row) }
            end

    <<~LATEX
      \\begin{enumerate}
      #{items.join("\n")}
      \\end{enumerate}
    LATEX
  end
end

def by_year_formatter(&formatter)
  lambda do |year, rows|
    "\\subsection*{#{year}}\n#{formatter.call(rows)}"
  end
end

def group_formatter(group_by:, &item_format)
  lambda do |rows|
    rows.group_by(&group_by)
        .map { |key, group| item_format.call(key, group) }
        .join("\n")
  end
end

def shorten_first_name(name)
  last, first = name.strip.split(/\s+/, 2)
  first ? "#{last} #{first[0]}." : last
end

def clean_names(rows, columns: ['Personen', 'Externe Person'])
  columns.each do |col|
    next unless rows.headers.include?(col)

    rows[col] = rows[col].map do |r|
      r.to_s.split('//').map(&method(:shorten_first_name)).join(', ')
    end
  end
end

def process_latex_pipeline(file_path, clean:, generate:, split: nil)
  # 1. Read data
  data = CSV.read(file_path, headers: true)

  # 2. Clean data
  cleaned_data = clean.call(data)

  # 3. Split data (optional, defaults to no splitting)
  split_data = split ? split.call(cleaned_data) : cleaned_data

  # 4. Generate LaTeX
  generate.call(split_data)
end
