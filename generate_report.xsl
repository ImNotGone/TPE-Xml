<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text"/> 

    <xsl:template match="/">
        <xsl:call-template name="getTitle" />
        <xsl:call-template name="getTable"/> 
        <xsl:text>
            \end{document}
        </xsl:text>
    </xsl:template>

    <xsl:template name="getTitle">
        <xsl:text>
            \documentclass{article}
            \usepackage[utf8]{inputenc}

            \title{Flight Report}
            \author{XML Group 01}
            \date{November 4, 2021}

            \begin{document}
            \maketitle
        </xsl:text>
    </xsl:template>

    <xsl:template name="getTableHeader">
        <xsl:text>
            \begin{table}
            \centering
            \begin{tabular}{|c|c|c|c|c|c|}
            \hline
            Flight Id &amp; Country &amp; Position &amp; Status &amp; Departure Airport &amp; Arrival Airport \\
            \hline
        </xsl:text>
    </xsl:template>

    <xsl:template name="getTable">
        <xsl:call-template name="getTableHeader"/>
        <xsl:for-each select="//flights_data/flight">
                <xsl:call-template name="getTableRow">
                    <xsl:with-param name="country" select="country" />
                    <xsl:with-param name="position" select="position" />
                    <xsl:with-param name="status" select="status" />
                    <xsl:with-param name="departure_airport" select="departure_airport/name" />
                    <xsl:with-param name="arrival_airport" select="arrival_airport/name" />
                    <xsl:with-param name="id" select="./@id" />
            </xsl:call-template>
        </xsl:for-each>
        <xsl:text>
            \end{tabular}
            \end{table}
        </xsl:text>
    </xsl:template>
   
    <xsl:template name="getTableRow">
        <xsl:param name="country" />
        <xsl:param name="position" />
        <xsl:param name="status" />
        <xsl:param name="departure_airport" />
        <xsl:param name="arrival_airport" />
        <xsl:param name="id" />
            \hline
            <xsl:value-of select="$id"/> &amp; <xsl:value-of select="$country/text()"/> &amp; (<xsl:value-of select="$position/lat/text()"/>, <xsl:value-of select="$position/lng/text()"/>) &amp; <xsl:value-of select="$status/text()"/> &amp; <xsl:value-of select="$departure_airport/text()"/> &amp; <xsl:value-of select="$arrival_airport/text()"/> \\
            \hline
    </xsl:template>

</xsl:stylesheet>