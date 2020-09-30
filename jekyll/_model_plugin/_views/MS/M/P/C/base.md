---
layout: page
title: Concept {{page.C.name}} in package {{page.C._package.name}}:{{page.C._model.name}}:{{page.C._model._ms.name}}
generated: true
nav_exclude: true
---

# {{C.title}}

{{page.C.summary}}

## Description

{{page.C.description}}

## Additional metadata

{% include entity-table.html entity=page.C headers=page.C._model._c_disp_headers %}

## Concept relationships

The following subheadings show Concept to Concept relationships in the model

### Parents

<table>
    <tr>
        <th>Concept</th>
        <th>Summary</th>
    </tr>
    {%- for entity in page.C._parents -%}
    {%- include entity-name-summary-tr.html entity=entity -%}
    {%- endfor -%}
</table>

### Children

{% assign sorted = page.C._children | sort -%}
{%- for entity_entry in sorted -%}
{%- assign entity = entity_entry[1] -%}
{%- include entity-href.html entity=entity -%}
{%- if forloop.last != true -%},
{% endif -%}
{%- endfor %}

### Ancestors

{%- assign sorted = page.C._ancestors | sort -%}
{% for entity_entry in sorted %}
{%- assign entity = entity_entry[1] -%}
{%- include entity-href.html entity=entity -%}
{% if forloop.last != true %}, {% endif %}
{% endfor %}

### Descendants

{%- assign sorted = page.C._descendants | sort -%}
{% for entity_entry in sorted %}
{%- assign entity = entity_entry[1] -%}
{% include entity-href.html entity=entity %}
{% if forloop.last != true %}, {% endif %}
{% endfor %}

## Element links

The following subheadings show Element to Concept relationships in the model


{% include debug.html object=page.C name="concept in MS/M/P/C/concept.html" on="false" hr="true" %}
