#!/bin/bash

# Input website URL
echo "Enter website URL: "
read website_url

# Fetch website headers
echo "Fetching website headers..."
curl -I $website_url > headers.txt

# Check SSL/TLS certificates
echo "Checking SSL/TLS certificates..."
openssl s_client -connect $website_url:443 </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > certificate.pem
openssl x509 -noout -checkend 86400 -in certificate.pem > certificate_status.txt

# Check DNS resolution
echo "Checking DNS resolution..."
dig $website_url > dns_configurations.txt

# Check robots.txt file
echo "Checking robots.txt file..."
curl -s $website_url/robots.txt > robots.txt

# Analyze HTTP headers
echo "Analyzing HTTP headers..."
echo "<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
  padding: 10px;
}
th {
  background-color: #333;
  color: white;
  text-align: center;
}
iframe {
  width: 100%;
  height: 600px;
}
</style>
</head>
<body>
<h2>Website Analysis Report</h2>
<table>
<tr>
<th>Header</th>
<th>Value</th>
</tr>" > report.html

# Parse HTTP headers and generate HTML table
while read -r line; do
  header=$(echo $line | cut -d':' -f1)
  value=$(echo $line | cut -d':' -f2- | sed 's/^ *//')
  echo "<tr>
<td>$header</td>
<td>$value</td>
</tr>" >> report.html
done < headers.txt

echo "</table>
<br>
<table>
<tr>
<th>DNS Configurations</th>
<th>Value</th>
</tr>" >> report.html

# Parse DNS configurations and generate HTML table
while read -r line; do
  key=$(echo $line | cut -d':' -f1)
  value=$(echo $line | cut -d':' -f2- | sed 's/^ *//')
  echo "<tr>
<td>$key</td>
<td>$value</td>
</tr>" >> report.html
done < dns_configurations.txt

echo "</table>
<br>
<table>
<tr>
<th>Check</th>
<th>Result</th>
</tr>
<tr>
<td>SSL/TLS Certificates</td>
<td><pre>" >> report.html
cat certificate_status.txt >> report.html
echo "</pre></td>
</tr>
<tr>
<td>Robots.txt File</td>
<td><pre>" >> report.html
cat robots.txt >> report.html
echo "</pre></td>
</tr>
<tr>
<td>WordPress or Joomla Detection</td>
<td><pre>" >> report.html
if curl -s -L $website_url | grep -q "wp-content"; then
  echo "WordPress" >> report.html
  echo "<br><br><b>WordPress Version:</b> $(curl -s -L $website_url/readme.html | grep "Version" | head -1 | awk '{print $NF}')" >> report.html
elif curl -s -L $website_url | grep -q "joomla"; then
  echo "Joomla" >> report.html
else
  echo "Unknown" >> report.html
fi
echo "</pre></td>
</tr>
<tr>
<td>Website Preview</td>
<td><iframe src='$website_url'></iframe></td>
</tr>
</table>
</body>
</html>" >> report.html

# Open HTML report in web browser
echo "Opening HTML report..."
xdg-open report.html
