# frozen_string_literal: true

require 'csv'
require_relative 'helper_methods'

def publication_latextify(year, publications)
  subsection = "\\subsection*{#{year}}"
  items = publications.map do |pub|
    "\t \\item #{sanitize(pub['APA-Format'])}"
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
  by_series = publications.group_by { |row| row['Serienname'] }

  generate_latex_for_publications(by_series['SPACE Working Paper Series'], 'data/space_wp.tex')
  generate_latex_for_publications(by_series['ICAE Working Paper Series'], 'data/icae_wp.tex')

  finished = by_series.reject { |series, _| WP_SERIES.include?(series) }.values.flatten(1)
  generate_latex_for_publications(finished, 'data/publications.tex')
end
