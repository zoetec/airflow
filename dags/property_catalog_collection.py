from datetime import datetime
from airflow.decorators import dag, task
from services.collector.catalog import load_sources
from services.collector.collect import collect_source
from services.collector.schedule import due, mark_run


@dag(dag_id="property_catalog_collection", start_date=datetime(2026, 8, 18),
     schedule="@hourly", catchup=False, tags=["rota-de-casa", "collection"])
def property_catalog_collection():
    @task
    def active_source_ids():
        if not due():
            return []
        return [source.id for source in load_sources() if source.status == "active"]

    @task
    def collect(source_id: str):
        result = collect_source(source_id)
        if result['status'] == 'collected':
            mark_run()
        return result

    collect.expand(source_id=active_source_ids())


property_catalog_collection()
