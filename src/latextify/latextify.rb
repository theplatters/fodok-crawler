require 'csv'

def generate_latex file, filename
  latex = "\\begin{itemize}\n"
  file.each do |row|
    latex += "\\item #{row['title']}: #{row['authors']} #{row['citation']} - #{row["type"]}\n"
  end
  File.write(filename,latex)
end

working_papers, finished_papers = CSV.read('data/publications.csv', headers: true)
  .sort_by {|row| [row['year'].to_i, row['authors']]}
  .reverse
  .partition {|row| row["type"] == "Working Paper"}

generate_latex(working_papers,"data/working_papers.tex")
puts 'LaTeX itemize list generated in working_papers.tex'
generate_latex(working_papers,"data/publications.tex")
puts 'LaTeX itemize list generated in publications.tex'

