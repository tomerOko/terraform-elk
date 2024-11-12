#!/bin/bash

terraform apply -auto-approve

osascript -e 'tell app "Terminal"
    do script "kubectl port-forward svc/kibana 5601:5601"
end tell'

osascript -e 'tell app "Terminal"
    do script "kubectl port-forward svc/elasticsearch 9200:9200"
end tell'

osascript -e 'tell app "Terminal"
    do script "kubectl port-forward deployment/main-mon 27017:27017" 
end tell'


