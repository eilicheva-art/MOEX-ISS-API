# MOEX-ISS-API
Реализована выгрузка истории сделок за нужный торговый день по рынку акций, сохранение данных в формате parquet и загрузка данных в greenplum

#### Используемые источники
[MOEX-ISS-API](https://iss.moex.com/iss/reference/) - данные торгов и отчетность эмитентов (МСФО/РСБУ).

[Документация Greenplum](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/6/greenplum-database/landing-index.html)

Интеграция Greenplum с внешними системами:
- [gpfdist](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/7/greenplum-database/utility_guide-ref-gpfdist.html)
- [pxf](https://yandex.cloud/ru/docs/managed-greenplum/operations/external-tables?utm_referrer=about%3Ablank)
- [copy](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/6/greenplum-database/ref_guide-sql_commands-COPY.html)
- [Loading Data with COPY](https://techdocs.broadcom.com/us/en/vmware-tanzu/data-solutions/tanzu-greenplum/6/greenplum-database/admin_guide-load-topics-g-loading-data-with-copy.html)
