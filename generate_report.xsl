<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:param name="qty" required="yes"/>
    <xsl:param name="ALL_VALUES" required="yes"/>
    
    <xsl:output method="text"/> 
    <xsl:template match="/">
    <xsl:choose>
        <xsl:when test="//flights_data/error">
            \documentclass[a4paper, 10pt]{minimal}
            \begin{document}
            An error was found while processing data and the report could not be generated properly. The error found was the following: "\verb|<xsl:value-of select="//flights_data/error"/>|"
            \end{document}
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="getTitle" />
            <xsl:call-template name="getTable"/> 
            \end{document}
        </xsl:otherwise>    
    </xsl:choose>
        
    </xsl:template>

    <xsl:template name="getTitle">
        \documentclass[a4paper, 10pt]{article}
        \usepackage{longtable}
        \usepackage[margin=1in]{geometry}
            
        \begin{document}
        \title{Flight Report}
        \author{XML Group 01}
        \date{\today}
        \maketitle
        \newpage
    </xsl:template>



    <xsl:template name="getTable">
        <xsl:call-template name="getTableHeader"/>
        <xsl:for-each select="//flights_data/flight">
            <xsl:if test="position() &lt;= $qty or $qty = $ALL_VALUES">
                <xsl:call-template name="getTableRow">
                    <xsl:with-param name="country" select="country" />
                    <xsl:with-param name="position" select="position" />
                    <xsl:with-param name="status" select="status" />
                    <xsl:with-param name="departure_airport" select="departure_airport/name" />
                    <xsl:with-param name="arrival_airport" select="arrival_airport/name" />
                    <xsl:with-param name="id" select="./@id" />
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
        \end{longtable}
    </xsl:template>
   
    <xsl:template name="getTableHeader">
        \begin{longtable}{| p{.10\textwidth}| p{.13\textwidth}| p{.12\textwidth}| p{.10\textwidth}| p{.19\textwidth}| p{.19\textwidth}|}
        \hline
        Flight Id &amp; Country &amp; Position &amp; Status &amp; Departure Airport &amp; Arrival Airport \\
        \hline
        \hline
    </xsl:template>

    <xsl:template name="getTableRow">
        <xsl:param name="country" />
        <xsl:param name="position" />
        <xsl:param name="status" />
        <xsl:param name="departure_airport" />
        <xsl:param name="arrival_airport" />
        <xsl:param name="id" />
        <xsl:value-of select="$id"/> &amp; <xsl:value-of select="$country"/> &amp; (<xsl:value-of select="$position/lat"/>, <xsl:value-of select="$position/lng"/>) &amp; <xsl:value-of select="$status"/> &amp; <xsl:value-of select="$departure_airport"/> &amp; <xsl:value-of select="$arrival_airport"/> \\
        \hline
    </xsl:template>

</xsl:stylesheet>