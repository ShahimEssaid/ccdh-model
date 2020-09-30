---
layout: page
title: Element {{page.E.name}} in package {{page.E._package.name}}:{{page.E._model.name}}:{{page.E._model._ms.name}}
nav_exclude: true
---
{% assign entity=page.E %}

{% include title-summary-desc.md entity=entity %}

{% include entity-table.md entity=entity headers=entity._m_disp_headers %}

{% include debug.md object=entity name="" on="false" hr="true" %}
