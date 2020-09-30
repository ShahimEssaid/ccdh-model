{% assign model = include.M %}
<li><a href="{{model._urls.base_html | relative_url }}">{{ model.name }}</a>
    {% include debug.md object=model name="model in m-rhtml" on="false" %}
    <ol><h3>Packages</h3>
    {% assign packages = model._packages | sort %}
    {% for package_entry in packages %}
    {% assign package = package_entry[1] %}
    {% include li/p-r.md P=package %}
    {% endfor %}
</ol>
</li>