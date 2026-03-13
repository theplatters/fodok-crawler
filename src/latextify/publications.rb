# frozen_string_literal: true

require 'csv'
require_relative 'helper_methods'
require 'uri'

def strip_apa_from_link(all_papers)
  url_regex = %r{https?://\S+}

  all_papers.each do |row|
    urls = row['APA-Format'].scan(url_regex)
    row['Links'] = urls.join(', ')
    row['APA-Format'] = row['APA-Format'].gsub(url_regex, '').strip
  end

  all_papers
end

def sort_wp_in_descending_order(publications)
  publications.sort_by! { |str| -(extract_wp_number(str['APA-Format']) || -1) }
end

def build_pub_item(pub)
  if pub['Links'] != ''
    "\t \\item \\href{#{pub['Links']}}{#{sanitize(pub['APA-Format'])}}"
  else
    "\t \\item #{sanitize(pub['APA-Format'])}"
  end
end

def publication_year_formatter
  by_year_formatter(
    formatter: simple_formatter(&method(:build_pub_item))
  )
end

def working_paper_year_formatter
  base = simple_formatter(&method(:build_pub_item))

  by_year_formatter(
    formatter: lambda do |rows|
      sort_wp_in_descending_order(rows)
      base.call(rows)
    end
  )
end

class CSV
  class Table
    def sort_by_year_apa
      sort_by do |row|
        [-row['Jahr'].to_i, row['APA-Format'].to_s]
      end
    end
  end
end

WP_SERIES = ['ICAE Working Paper Series', 'SPACE Working Paper Series'].freeze

def parse_publications
  publications = CSV.read('data/publikationen.csv', headers: true).sort_by_year_apa
  publications = strip_apa_from_link(publications)
  by_series = publications.group_by { |row| row['Serienname'] }

  finished = by_series.reject { |series, _| WP_SERIES.include?(series) }.values.flatten(1)
  generate_latex(
    by_series['SPACE Working Paper Series'],
    'data/space_wp.tex',
    formatter: working_paper_year_formatter
  )

  generate_latex(
    by_series['ICAE Working Paper Series'],
    'data/icae_wp.tex',
    formatter: working_paper_year_formatter
  )

  generate_latex(
    finished,
    'data/publications.tex',
    formatter: publication_year_formatter
  )
end
