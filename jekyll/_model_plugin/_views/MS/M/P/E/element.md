---
layout: page
title: Element {{E.name}} in package {{E._package.name}}:{{E._model.name}}:{{E._model._ms.name}}
generated: true
nav_exclude: true
---
{% raw %}
<h1>{{page.E.name}} element</h1>
{% include entity-table.html entity=page.E headers=page.E._model._e_disp_headers %}

{% include debug.html object=page.E name="element in MS/M/P/E/element.html" on="false" hr="true" %}
{% endraw %}