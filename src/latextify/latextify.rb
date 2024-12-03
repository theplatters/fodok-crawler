require 'csv'

latex = "\\begin{itemize}\n"

CSV.foreach('data/publications.csv', headers: true) do |row|
  latex += "\\item #{row['title']}: #{row['authors']} #{row['citation']}\n"
end

latex += "\\end{itemize}\n"

File.write('data/output.tex', latex)
puts 'LaTeX itemize list generated in output.tex'
