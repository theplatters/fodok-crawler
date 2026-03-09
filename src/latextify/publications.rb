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

def publication_latextify(year, publications)
  subsection = "\\subsection*{#{year}}"
  items = publications.map do |pub|
    if pub['Links'] != ''
      "\t \\item \\href{#{pub['Links']}}{#{sanitize(pub['APA-Format'])}}"
    else
      "\t \\item #{sanitize(pub['APA-Format'])}"
    end
  end.join("\n")

  subsection + "
\\begin{enumerate}
#{items}
\\end{enumerate}\n"
end

def generate_latex_for_publications(rows, out_filename)
  latex = group_by_year(rows, &method(:publication_latextify))
  File.write(out_filename, latex)
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

  generate_latex_for_publications(by_series['SPACE Working Paper Series'], 'data/space_wp.tex')
  generate_latex_for_publications(by_series['ICAE Working Paper Series'], 'data/icae_wp.tex')

  finished = by_series.reject { |series, _| WP_SERIES.include?(series) }.values.flatten(1)
  generate_latex_for_publications(finished, 'data/publications.tex')
end
