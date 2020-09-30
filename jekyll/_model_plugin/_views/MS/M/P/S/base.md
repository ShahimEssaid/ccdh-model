---
layout: page
title: Structure {{page.S.name}} in package {{page.S._package.name}}:{{page.S._model.name}}:{{page.S._model._ms.name}}
nav_exclude: true
---
{% assign entity=page.S %}

{% include title-summary-desc.md entity=entity %}

{% include entity-table.md entity=entity headers=entity._m_disp_headers %}

{% include debug.md object=entity name="" on="false" hr="true" %}
