echo "This is R2RML Parser 0.8-alpha. Run with -h for help on options."
java -Xms128m -Xmx1024m -cp "/opt/r2rml/*;/opt/r2rml/lib/*;" -jar /opt/r2rml/lib/r2rml-parser-0.8.jar $1 $2
echo "R2RML Parser 0.8-alpha. Done."
