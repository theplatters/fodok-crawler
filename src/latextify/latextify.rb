require 'csv'

def generate_latex file, filename
  latex = "\\begin{itemize}\n"
  year = 0
  file.each do |row|
    if row['year'] != year
      year = row['year']
      latex += "\\end{itemize} \n \\subsection{#{year}} \n \\begin{itemize} \n"
    end
    latex += "\t \\item #{row['title']}: #{row['authors']} #{row['citation']} - #{row["type"]}\n"
  end
  latex += "\\end{itemize}"
  File.write(filename,latex)
end

working_papers, finished_papers = CSV.read('data/publications.csv', headers: true)
  .sort_by {|row| [row['year'].to_i, row['authors']]}
  .reverse
  .partition {|row| row["type"] == "Working Paper"}

generate_latex(working_papers,"data/working_papers.tex")
puts 'LaTeX itemize list generated in working_papers.tex'
generate_latex(finished_papers,"data/publications.tex")
puts 'LaTeX itemize list generated in publications.tex'

