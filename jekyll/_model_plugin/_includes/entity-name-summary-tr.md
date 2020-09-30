{%- assign entity = include.entity -%}
{%- assign summary = entity.summary -%}
<tr><td>{% include entity-href.md entity=entity %}</td><td>{{summary}}</td></tr>
