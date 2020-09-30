---
layout: page
title: Model {{page.M._model.name}} in model set {{page.M._model._ms.name}}
generated: true
nav_exclude: true
---
{% raw %}
<h1>{{page.M.name}} model</h1>
{% include entity-table.html entity=page.M headers=page.M._m_disp_headers %}

{% include debug.html object=page.M name="model in MS/M/model.html" on="false" hr="true" %}
{% endraw %}

