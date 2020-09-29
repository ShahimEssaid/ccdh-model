---
layout: page
title: Concept {{C.name}} in package {{C._package.name}}:{{C._model.name}}:{{C._model._ms.name}}
generated: true
nav_exclude: true
---

# {{C.title}}

{{C.summary}}

## Description

{{C.description}}

## Additional metadata

{% include entity-table.html entity=C headers=C._model._c_disp_headers %}

## Concept relationships

The following subheadings show Concept to Concept relationships in the model

### Parents

<table>
    <tr>
        <th>Concept</th>
        <th>Summary</th>
    </tr>
    {%- for entity in C._parents -%}
    {%- include entity-name-summary-tr.html entity=entity -%}
    {%- endfor -%}
</table>

### Children

{% assign sorted = C._children | sort -%}
{%- for entity_entry in sorted -%}
{%- assign entity = entity_entry[1] -%}
{%- include entity-href.html entity=entity -%}
{%- if forloop.last != true -%},
{% endif -%}
{%- endfor %}

### Ancestors

{%- assign sorted = C._ancestors | sort -%}
{% for entity_entry in sorted %}
{%- assign entity = entity_entry[1] -%}
{%- include entity-href.html entity=entity -%}
{% if forloop.last != true %}, {% endif %}
{% endfor %}

### Descendants

{%- assign sorted = C._descendants | sort -%}
{% for entity_entry in sorted %}
{%- assign entity = entity_entry[1] -%}
{% include entity-href.html entity=entity %}
{% if forloop.last != true %}, {% endif %}
{% endfor %}

## Element links

The following subheadings show Element to Concept relationships in the model


{% include debug.html object=C name="concept in MS/M/P/C/concept.html" on="false" hr="true" %}
