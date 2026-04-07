# frozen_string_literal: true

require 'csv'
require_relative 'helper_methods'

WP_SERIES = ['ICAE Working Paper Series', 'SPACE Working Paper Series'].freeze

def strip_apa_from_link(all_papers)
  url_regex = %r{https?://\S+}

  all_papers.each do |row|
    urls = row[Columns::APA_FORMAT].scan(url_regex)
    row['Links'] = urls.join(', ')
    row[Columns::APA_FORMAT] = row[Columns::APA_FORMAT].gsub(url_regex, '').strip
  end

  all_papers
end

def sort_wp_in_descending_order!(publications)
  publications.sort_by! { |row| -(extract_wp_number(row[Columns::APA_FORMAT]) || -1) }
end

def build_pub_item(pub)
  sanitized_apa = sanitize(pub[Columns::APA_FORMAT])
  if pub['Links'] && !pub['Links'].empty?
    "\t \\item \\href{#{pub['Links']}}{#{sanitized_apa}}"
  else
    "\t \\item #{sanitized_apa}"
  end
end

def publication_year_formatter
  section_formatter(&simple_formatter(&method(:build_pub_item)))
end

def working_paper_year_formatter
  base = simple_formatter(&method(:build_pub_item))

  section_formatter do |rows|
    sort_wp_in_descending_order!(rows)
    base.call(rows)
  end
end

def split_into_wp(publications)
  space_wp = []
  icae_wp = []
  published = []

  publications.each do |row|
    case row['Serienname']
    when 'SPACE Working Paper Series'
      space_wp << row
    when 'ICAE Working Paper Series'
      icae_wp << row
    else
      published << row
    end
  end

  [space_wp, icae_wp, published]
end

def split_into_blog(published)
  published.each do |row|
    row['Blog'] = row[Columns::APA_FORMAT].include?('Blog Beitrag')
    row[Columns::APA_FORMAT] = row[Columns::APA_FORMAT].gsub('Blog Beitrag', '').strip
  end
  published.partition { |row| row['Blog'] }
end

def generate_latex_for_publications(space_wp, icae_wp, published, blog)
  configs = {
    'data/space_wp.tex' => [space_wp, working_paper_year_formatter],
    'data/icae_wp.tex' => [icae_wp, working_paper_year_formatter],
    'data/publications.tex' => [published, publication_year_formatter],
    'data/blog.tex' => [blog, publication_year_formatter]
  }

  configs.each do |path, (items, formatter)|
    generate_latex(items, path, formatter: formatter) unless items.empty?
  end
end

def clean_and_sort_publications(data)
  # Sort by year descending, then APA format
  sorted_rows = data.sort_by { |r| [-r[Columns::YEAR].to_i, r[Columns::APA_FORMAT].to_s] }
  sorted_table = CSV::Table.new(sorted_rows)

  strip_apa_from_link(sorted_table)
  sorted_table.reject { |r| in_2026?(r) }
end

def split_all_publications(data)
  space_wp, icae_wp, published = split_into_wp(data)
  blog, published = split_into_blog(published)
  [space_wp, icae_wp, published, blog]
end

def parse_publications
  process_latex_pipeline(
    'data/publikationen.csv',
    clean: method(:clean_and_sort_publications),
    split: method(:split_all_publications),
    generate: ->(args) { generate_latex_for_publications(*args) }
  )
end
