{% assign headers = include.headers %}
{% assign entity = include.entity %}

## Additional fields

<table>
    <tr>
        <th>Name</th>
        <th>Value</th>
    </tr>
    {% for header in headers %}
    {%- assign val = entity[header] -%}
    {%- assign type = entity[header] | object_type -%}  
    {% if val.size > 0 %}
    <tr>
        <td>{{header}}</td>
        <td>

            {%- if type == "nil" -%}
                nil value
            {%- elsif type == "string" -%}
                {{ val | markdownify }}
            {%- elsif type == "http" -%}
                <a href="{{val}}">{{val}}</a>
            {%- elsif type == "mhash" -%}
                <a href="{{val | entity_home_url | relative_url }}">{{val._entity_name | default: "NONAME"}}</a>
            {%- elsif type == "hash" -%}
                {%- assign sorted = val | sort -%}
                {%- for hash_entry in sorted -%}
                {%- assign htype = hash_entry[1] | object_type -%}
                    {%- if htype == "mhash" -%}
                        <a href="{{hash_entry[1] | entity_home_url | relative_url }}">{{hash_entry[1]._entity_name | default: "NONAME"}}</a>
                    {%- else -%}
                        {{hash_entry[1]}}
                    {%- endif -%}
                {% if forloop.last != true %}, {% endif %}
                {%- endfor -%}
            {%- elsif type == "array" -%}
                {%- for entry in val -%}
                    {%- assign htype = entry | object_type -%}
                    {%- if htype == "mhash" -%}
                    <a href="{{entry | entity_home_url | relative_url }}">{{hash_entry[1]._entity_name | default: "NONAME"}}</a>
                    {%- else -%}
                    {{entry}}
                    {%- endif -%}
                {% if forloop.last != true %},<br> {% endif %}
                {%- endfor -%}
            {%- elsif type == "numeric" -%}
                {{ val }}
            {%- elsif type == "csvtable" -%}
                "CSV::TABLE"
            {%- else -%}
                Unknown value: {{val}}
            {%- endif -%}
        </td>
    </tr>
    {% endif %}
    {% endfor %}
</table>