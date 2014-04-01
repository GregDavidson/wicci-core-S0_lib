
SELECT xml_kind(t, '', 'title', 'id="title"' )
FROM xml_doctype('html', 'html') t;

SELECT get_xml_attrs(ARRAY['id="title"']);

SELECT get_xml_attrs('id="title"');



SELECT attr[1],attr[2] FROM parse_attrs_('id="title"') attr;

SELECT attr, try_get_xml_attr( attr[1], attr[2] )FROM parse_attrs_('id="title"') attr;

SELECT try_get_xml_attr( 'id', 'title' );

SELECT try_xml_attr_name('id') IS NULL;
