---
layout: page
title: "Package {{page.P.name}} in model {{page.P._model.name}}:{{page.P._model._ms.name}}"
nav_exclude: true
---
{% assign entity=page.P %}

{% include title-summary-desc.md entity=entity %}

{% include entity-table.md entity=entity headers=entity._m_disp_headers %}

{% include debug.md object=entity name="" on="false" hr="true" %}


