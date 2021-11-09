echo -e "${GREEN}[INFO ]${WHITE} Processing report.tex"
`pdflatex.exe report.tex &>/dev/null`
`rm -rf report.aux`
`rm -rf report.log`
echo -e "${GREEN}[INFO ]${WHITE} File report.pdf created"