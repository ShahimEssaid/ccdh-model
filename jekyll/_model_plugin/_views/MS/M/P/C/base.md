---
layout: page
title: Concept {{page.C.name}} in package {{page.C._package.name}}:{{page.C._model.name}}:{{page.C._model._ms.name}}
nav_exclude: true
---
{% assign entity=page.C %}

{% include title-summary-desc.md entity=entity %}

{% include entity-table.md entity=entity headers=entity._m_disp_headers %}

{% include debug.md object=entity name="" on="false" hr="true" %}


## Concept relationships

The following subheadings show Concept to Concept relationships in the model

### Parents

<table>
    <tr>
        <th>Concept</th>
        <th>Summary</th>
    </tr>
    {%- for entity in page.C._parents -%}
    {%- include entity-name-summary-tr.md entity=entity -%}
    {%- endfor -%}
</table>

### Children

{% assign sorted = page.C._children | sort -%}
{%- for entity_entry in sorted -%}
{%- assign entity = entity_entry[1] -%}
{%- include entity-href.md entity=entity -%}
{%- if forloop.last != true -%},
{% endif -%}
{%- endfor %}

### Ancestors

{%- assign sorted = page.C._ancestors | sort -%}
{% for entity_entry in sorted %}
{%- assign entity = entity_entry[1] -%}
{%- include entity-href.md entity=entity -%}
{% if forloop.last != true %}, {% endif %}
{% endfor %}

### Descendants

{%- assign sorted = page.C._descendants | sort -%}
{% for entity_entry in sorted %}
{%- assign entity = entity_entry[1] -%}
{% include entity-href.md entity=entity %}
{% if forloop.last != true %}, {% endif %}
{% endfor %}

## Element links

The following subheadings show Element to Concept relationships in the model


{% include debug.md object=page.C name="concept in MS/M/P/C/concept.html" on="false" hr="true" %}
