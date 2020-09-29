---
layout: page
title: Package {{P._package.name}} in model {{P._model.name}}:{{P._model._ms.name}}
generated: true
nav_exclude: true
---
{% raw %}
<h1>{{page.P.name}} package</h1>
{% include entity-table.html entity=page.P headers=page.P._model._p_disp_headers %}

{% include debug.html object=page.P name="package in MS/M/P/package.html" on="false" hr="true" %}
{% endraw %}

