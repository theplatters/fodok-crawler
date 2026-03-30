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
    &simple_formatter(&method(:build_pub_item))
  )
end

def working_paper_year_formatter
  base = simple_formatter(&method(:build_pub_item))

  by_year_formatter do |rows|
    sort_wp_in_descending_order(rows)
    base.call(rows)
  end
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

def clean_up_publications(publications)
  publications = strip_apa_from_link(publications)
  publications.reject do |r|
    in_2026?(r)
  end
end

def split_into_wp(publications)
  by_series = publications.group_by { |row| row['Serienname'] }
  published = by_series.reject { |series, _| WP_SERIES.include?(series) }.values.flatten(1)
  [by_series['SPACE Working Paper Series'], by_series['ICAE Working Paper Series'], published]
end

def generate_latex_for_publications(space_wp, icae_wp, published, blog)
  {
    'data/space_wp.tex' => [space_wp, working_paper_year_formatter],
    'data/icae_wp.tex' => [icae_wp, working_paper_year_formatter],
    'data/publications.tex' => [published, publication_year_formatter],
    'data/blog.tex' => [blog, publication_year_formatter]
  }.each do |path, (items, formatter)|
    generate_latex(items, path, formatter: formatter)
  end
end

def split_into_blog(published)
  published.each do |row|
    row['Blog'] = row['APA-Format'].include?('Blog Beitrag')
    row['APA-Format'] = row['APA-Format'].gsub('Blog Beitrag', '').strip
  end
  published.partition { |row| row['Blog'] }
end

def parse_publications
  publications = CSV.read('data/publikationen.csv', headers: true).sort_by_year_apa
  publications = clean_up_publications(publications)
  space_wp, icae_wp, published = split_into_wp(publications)
  blog, published = split_into_blog(published)
  generate_latex_for_publications(space_wp, icae_wp, published, blog)
end
