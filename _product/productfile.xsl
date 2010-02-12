<!--  usage:
   xsltproc productfile.xsl productdefintion.xml
-->
<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl"
>
  <xsl:output method="xml" media-type="text/xml" indent="yes" />
  <xsl:template match="/">
    <xsl:for-each select="/productdefinition/mediasets/media/archsets/archset">
      <xsl:variable name="product_id" select="../../@product" />
      <xsl:variable name="filename" select="concat($product_id,'-',@ref,'.prod')" />
      <xsl:message>Filename is: <xsl:value-of select="$filename" /></xsl:message>
      <xsl:variable name="product" select="/productdefinition/products/product[@id=$product_id]" />
      <exsl:document href="{$filename}" indent="yes">
        <product>
          <vendor><xsl:value-of select="$product/vendor" /></vendor>
          <name><xsl:value-of select="$product/name" /></name>
          <version><xsl:value-of select="$product/version" /></version>
          <release><xsl:value-of select="$product/release" /></release>
          <!-- TODO: register -->
          <register>
            <target><xsl:value-of select="$product/register/target" /></target>
            <release><xsl:value-of select="$product/register/release" /></release>
            <flavor><xsl:value-of select="$product/register/flavor" /></flavor>
          </register>
          <updaterepokey><xsl:value-of select="$product/updaterepokey" /></updaterepokey>
          <summary><xsl:value-of select="$product/summary" /></summary>
          <description><xsl:value-of select="$product/description" /></description>
          <linguas>
            <xsl:for-each select="$product/linguas/language">
              <lang><xsl:value-of select="text()" /></lang>
            </xsl:for-each>
          </linguas>
          <urls>
            <xsl:for-each select="$product/urls/url">
              <xsl:element name="url">
                <xsl:attribute name="name"><xsl:value-of select="@type" /></xsl:attribute>
                <xsl:value-of select="@href" />
              </xsl:element>
            </xsl:for-each>
          </urls>
        </product>
      </exsl:document>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
