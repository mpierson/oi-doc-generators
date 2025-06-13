<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform SPS config export to Markdown

  Author: M Pierson
  Date: Feb 2025
  Version: 0.90

  Use /opt/scb/var/db/scb.xml, or extract config from export/bundle.

 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" >
  
  <!-- Function to convert IP string to integer -->
  <xsl:function name="ois:ip-to-int" as="xs:integer">
    <xsl:param name="ip" as="xs:string"/>
    
    <xsl:variable name="octets" select="tokenize($ip, '\.')"/>
    <xsl:variable name="result" as="xs:integer">
      <xsl:value-of select="
        xs:integer($octets[1]) * 16777216 + 
        xs:integer($octets[2]) * 65536 + 
        xs:integer($octets[3]) * 256 + 
        xs:integer($octets[4])"/>
    </xsl:variable>
    
    <xsl:value-of select="$result"/>
  </xsl:function>
  
  <!-- Function to convert CIDR to netmask integer -->
  <xsl:function name="ois:cidr-to-mask-int" as="xs:integer">
    <xsl:param name="cidr" as="xs:integer"/>
    
    <xsl:variable name="all-ones" select="4294967295"/> <!-- 2^32 - 1 -->
    <xsl:variable name="shift" select="32 - $cidr"/>
    <xsl:variable name="inverted-part" select="xs:integer(ois:power(2, $shift)) - 1"/>
    
    <xsl:value-of select="$all-ones - $inverted-part"/>
  </xsl:function>


  <!-- Power function to calculate base^exponent -->
  <xsl:function name="ois:power" as="xs:integer">
    <xsl:param name="base" as="xs:integer"/>
    <xsl:param name="exponent" as="xs:integer"/>

    <xsl:sequence select="
      if ($exponent = 0) then 1
      else if ($exponent = 1) then $base
      else if ($exponent mod 2 = 0) then ois:power($base * $base, $exponent idiv 2)
      else $base * ois:power($base * $base, $exponent idiv 2)
    "/>
  </xsl:function>
  
  <!-- Function to check if IP is in network, given IP and network pattern -->
  <xsl:function name="ois:is-ip-in-network" as="xs:boolean">
    <xsl:param name="ip" as="xs:string"/>
    <xsl:param name="network" as="xs:string"/><!-- binary string -->

    <xsl:variable name="ip-int" select="ois:ip-to-int($ip)"/>
    <xsl:variable name="ip-bin" select="ois:pad-left(ois:integer-to-binary($ip-int), 32)" />
    <xsl:variable name="masked-ip" select="ois:binary-and($ip-bin, $network)"/>
    
    <xsl:value-of select="$masked-ip eq $network"/>
  </xsl:function>
  

  <!-- Function to perform bitwise AND of two integers -->
  <xsl:function name="ois:bitwise-and" as="xs:integer">
    <xsl:param name="a" as="xs:integer"/>
    <xsl:param name="b" as="xs:integer"/>
    
    <!-- Convert to binary representations -->
    <xsl:variable name="bin-a" select="ois:integer-to-binary($a)"/>
    <xsl:variable name="bin-b" select="ois:integer-to-binary($b)"/>
    
    <!-- Make both strings the same length by padding with leading zeros -->
    <xsl:variable name="max-length" select="max((string-length($bin-a), string-length($bin-b)))"/>
    <xsl:variable name="padded-a" select="ois:pad-left($bin-a, $max-length)"/>
    <xsl:variable name="padded-b" select="ois:pad-left($bin-b, $max-length)"/>
    
    <!-- Perform bitwise AND -->
    <xsl:variable name="result-binary" select="ois:binary-and($padded-a, $padded-b)"/>
    
    <!-- Convert back to integer -->
    <xsl:value-of select="ois:binary-to-integer($result-binary)"/>
  </xsl:function>
  
  <!-- Helper function to convert integer to binary string -->
  <xsl:function name="ois:integer-to-binary" as="xs:string">
    <xsl:param name="n" as="xs:integer"/>
    
    <xsl:choose>
      <xsl:when test="$n = 0">0</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="
          if ($n &lt; 0) then
            ois:twos-complement(ois:integer-to-binary-positive(- $n), 32)
          else
            ois:integer-to-binary-positive($n)
        "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Helper function to convert positive integer to binary string -->
  <xsl:function name="ois:integer-to-binary-positive" as="xs:string">
    <xsl:param name="n" as="xs:integer"/>
    
    <xsl:sequence select="
      if ($n = 0) then ''
      else concat(ois:integer-to-binary-positive($n idiv 2), $n mod 2)
    "/>
  </xsl:function>
  
  <!-- Helper function to pad a string with leading characters -->
  <xsl:function name="ois:pad-left" as="xs:string">
    <xsl:param name="str" as="xs:string"/>
    <xsl:param name="length" as="xs:integer"/>

    <xsl:variable name="pad" select="'0'" as="xs:string"/>
    
    <xsl:sequence select="
      if (string-length($str) >= $length) then $str
      else ois:pad-left(concat($pad, $str), $length)
    "/>
  </xsl:function>
  
  <!-- Helper function to perform AND on two binary strings -->
  <xsl:function name="ois:binary-and" as="xs:string">
    <xsl:param name="a" as="xs:string"/>
    <xsl:param name="b" as="xs:string"/>
    
    <xsl:sequence select="
      if (string-length($a) = 0) then ''
      else concat(
        if (substring($a, 1, 1) = '1' and substring($b, 1, 1) = '1') then '1' else '0',
        ois:binary-and(substring($a, 2), substring($b, 2))
      )
    "/>
  </xsl:function>
  
  <!-- Helper function to convert binary string to integer -->
  <xsl:function name="ois:binary-to-integer" as="xs:integer">
    <xsl:param name="binary" as="xs:string"/>
    
    <xsl:choose>
      <xsl:when test="starts-with($binary, '1') and string-length($binary) = 32">
        <!-- Handle two's complement for negative numbers -->
        <xsl:variable name="inverted" select="ois:binary-invert($binary)"/>
        <xsl:variable name="positive" select="ois:binary-to-integer-positive($inverted) + 1"/>
        <xsl:value-of select="-$positive"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="ois:binary-to-integer-positive($binary)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Helper function to convert positive binary string to integer -->
  <xsl:function name="ois:binary-to-integer-positive">
    <xsl:param name="binary" as="xs:string"/>
    
    <xsl:sequence select="
      if (string-length($binary) = 0) then 0
      else number(substring($binary, string-length($binary), 1)) +
           2 * ois:binary-to-integer-positive(substring($binary, 1, string-length($binary) - 1))
    "/>
  </xsl:function>
  
  <!-- Helper function to invert binary digits (for two's complement) -->
  <xsl:function name="ois:binary-invert" as="xs:string">
    <xsl:param name="binary" as="xs:string"/>
    
    <xsl:sequence select="
      if (string-length($binary) = 0) then ''
      else concat(
        if (substring($binary, 1, 1) = '0') then '1' else '0',
        ois:binary-invert(substring($binary, 2))
      )
    "/>
  </xsl:function>
  
  <!-- Helper function to convert to two's complement -->
  <xsl:function name="ois:twos-complement" as="xs:string">
    <xsl:param name="binary" as="xs:string"/>
    <xsl:param name="bits" as="xs:integer"/>
    
    <xsl:variable name="padded" select="ois:pad-left($binary, $bits)"/>
    <xsl:variable name="inverted" select="ois:binary-invert($padded)"/>
    
    <!-- Increment by 1 (two's complement) -->
    <xsl:variable name="plus-one" select="
      ois:binary-add($inverted, ois:pad-left('1', string-length($inverted)), '0')
    "/>
    
    <xsl:value-of select="$plus-one"/>
  </xsl:function>
  
  <!-- Helper function to add two binary strings -->
  <xsl:function name="ois:binary-add" as="xs:string">
    <xsl:param name="a" as="xs:string"/>
    <xsl:param name="b" as="xs:string"/>
    <xsl:param name="carry" as="xs:string"/>
    
    <xsl:choose>
      <xsl:when test="string-length($a) = 0 and string-length($b) = 0">
        <xsl:value-of select="$carry"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="a-bit" select="
          if (string-length($a) = 0) then '0'
          else substring($a, string-length($a), 1)
        "/>
        <xsl:variable name="b-bit" select="
          if (string-length($b) = 0) then '0'
          else substring($b, string-length($b), 1)
        "/>
        
        <xsl:variable name="sum" select="
          if ($a-bit = '1' and $b-bit = '1') then
            if ($carry = '1') then '1' else '0'
          else if (($a-bit = '1' or $b-bit = '1') and $carry = '1') then
            '0'
          else if ($a-bit = '1' or $b-bit = '1' or $carry = '1') then
            '1'
          else
            '0'
        "/>
        
        <xsl:variable name="new-carry" select="
          if (($a-bit = '1' and $b-bit = '1') or 
              (($a-bit = '1' or $b-bit = '1') and $carry = '1')) then
            '1'
          else
            '0'
        "/>
        
        <xsl:value-of select="concat(
          ois:binary-add(
            if (string-length($a) = 0) then '' else substring($a, 1, string-length($a) - 1),
            if (string-length($b) = 0) then '' else substring($b, 1, string-length($b) - 1),
            $new-carry
          ),
          $sum
        )"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Example usage: Test template -->
  <xsl:template name="test-bitwise-and">
    <xsl:param name="a" select="42" as="xs:integer"/>  <!-- 101010 in binary -->
    <xsl:param name="b" select="15" as="xs:integer"/>  <!-- 001111 in binary -->
    
    <test-results>
      <inputs>
        <a decimal="{$a}" binary="{ois:integer-to-binary($a)}"/>
        <b decimal="{$b}" binary="{ois:integer-to-binary($b)}"/>
      </inputs>
      <bitwise-and-result>
        <decimal value="{ois:bitwise-and($a, $b)}"/>
        <binary value="{ois:integer-to-binary(ois:bitwise-and($a, $b))}"/>
        <expected value="10"/> <!-- 42 AND 15 = 10 -->
      </bitwise-and-result>
    </test-results>
  </xsl:template>
  
</xsl:stylesheet>
