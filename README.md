## IP Comparison Checker

This script retrieves IP address information from various sources (platforms and databases) and compares the data to highlight discrepancies and agreements.

### Features

- **Multi-Platform IP Retrieval:** Supports retrieving IP addresses using `ip`, `hostname`, `ifconfig`, and `curl` commands, ensuring compatibility across different systems.
- **Multiple IP Databases:** Fetches information from four reputable IP databases:
    - `whois`
    - `ipinfo.io`
    - `ipapi.co`
    - `RIPE`
- **Comprehensive Information Retrieval:** Extracts key details such as ASN, organization, country, region, and city.
- **Data Comparison and Analysis:** Performs a basic comparison of the retrieved data to identify discrepancies and agreements across platforms and databases.
- **Error Handling:** Includes error handling mechanisms to prevent script termination in case of API issues or command failures.
- **Formatted Output:** Presents results in a structured and color-coded format for enhanced readability.

### Requirements

- `bash` (shell interpreter)
- `curl` (for fetching data from APIs)
- `jq` (for parsing JSON responses)
- `whois` (for querying the whois database)

### Usage

1. Save the script to your system:
   ```bash
   wget https://raw.githubusercontent.com/EngineeringSample/ip_comparison_checker/main/ip_comparison_checker.sh
   ```
2. Make the script executable:
   ```bash
   chmod +x ip_comparison_checker.sh
   ```
3. Run the script:
   ```bash
   ./ip_comparison_checker.sh 
   ```

or 
```bash
   wget https://raw.githubusercontent.com/EngineeringSample/ip_comparison_checker/main/ip_comparison_checker.sh && chmod +x ip_comparison_checker.sh && ./ip_comparison_checker.sh
   ```


The script will retrieve the IP address using different methods, query the specified databases, and present the information along with a basic comparison analysis.

### Output

The script generates output in the following format:

```
--- IP Address Retrieval ---
Platform a: 192.168.1.100
Platform b: 192.168.1.100
Platform c: 192.168.1.100
Platform d: 192.168.1.100

--- Information from Databases ---
Platform a:
  whois:
    origin: AS12345 Example Organization
    country: US
    stateprov: CA
  ipinfo.io:
    "Example Organization", "United States", "California", "Mountain View", "AS12345"
  ipapi.co:
    12345, "United States", "California", "Mountain View"
  RIPE:
    "AS12345", "Example Organization", "US"
  ... (Output for other platforms)

--- Basic Comparison ---
Database: whois
  ASN: Consistent (AS12345)
  Country: Consistent (US)
  Region: Consistent (CA)
  City: Discrepancies
    Mountain View
    ... 
  ... (Comparison for other databases)
```

### Future Enhancements

- More advanced comparison algorithms for handling subtle data variations.
- Data visualization options for intuitive understanding.
- User input options for customizable comparisons.
- Support for additional IP databases.
- Output formatting options (CSV, JSON).
- Caching mechanisms for improved performance.

### Contributing

Contributions, suggestions, and bug reports are welcome! Feel free to open issues or submit pull requests on the GitHub repository.
