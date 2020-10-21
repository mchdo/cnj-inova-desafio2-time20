--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4 (Debian 12.4-1.pgdg100+1)
-- Dumped by pg_dump version 12.4 (Debian 12.4-1.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'LATIN1';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bd_marvinjud; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE bd_marvinjud WITH TEMPLATE = template0 ENCODING = 'LATIN1' LC_COLLATE = 'pt_BR.ISO-8859-1' LC_CTYPE = 'pt_BR.ISO-8859-1';


ALTER DATABASE bd_marvinjud OWNER TO postgres;

\connect bd_marvinjud

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'LATIN1';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: registro_validacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registro_validacao (
    "anoProcesso" integer,
    "dadosBasicos.classeProcessual" integer,
    "dadosBasicos.numero" character varying(20) NOT NULL,
    "dadosBasicos.orgaoJulgador.codigoOrgao" character varying(20),
    "dadosBasicos.orgaoJulgador.nomeOrgao" character varying(255),
    "geoLatitudeOrgao" double precision,
    "geoLongitudeOrgao" double precision,
    "geoNomeMunicipio" character varying(255),
    "geoUF" character varying(10),
    "millisInsercao" numeric(32,0) NOT NULL,
    "qtdAssuntos" integer,
    "qtdAssuntosFalha" integer,
    "qtdMovimentos" integer,
    "qtdMovimentosFalha" integer,
    "qtdRegras" integer,
    "qtdRegrasFalha" integer,
    "siglaTribunal" character varying(10),
    "esferaJustica" character varying(255),
    grau character varying(10)
);


ALTER TABLE public.registro_validacao OWNER TO postgres;

--
-- Name: regras; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.regras (
    uid text NOT NULL,
    id_ text NOT NULL,
    nome_atributo text DEFAULT ''::text NOT NULL,
    atributo_obrigatorio boolean DEFAULT false,
    nome_regra text DEFAULT ''::text NOT NULL,
    detalhe_regra text DEFAULT ''::text NOT NULL,
    escopo text DEFAULT 'processo'::text NOT NULL,
    condicao text DEFAULT ''::text NOT NULL,
    script text DEFAULT ''::text NOT NULL,
    script_sugestao text DEFAULT ''::text NOT NULL,
    tipo text DEFAULT 'warning'::text NOT NULL,
    ativa boolean DEFAULT false,
    criada_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    criada_por text DEFAULT ''::text NOT NULL,
    modificada_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modificada_por text DEFAULT ''::text NOT NULL,
    excluida boolean DEFAULT false
);


ALTER TABLE public.regras OWNER TO postgres;

--
-- Name: vw_registro_validacao; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_registro_validacao AS
 SELECT registro_validacao."anoProcesso",
    registro_validacao."dadosBasicos.classeProcessual",
    registro_validacao."dadosBasicos.numero",
    registro_validacao."dadosBasicos.orgaoJulgador.codigoOrgao",
    registro_validacao."dadosBasicos.orgaoJulgador.nomeOrgao",
    registro_validacao."geoLatitudeOrgao",
    registro_validacao."geoLongitudeOrgao",
    registro_validacao."geoNomeMunicipio",
    registro_validacao."geoUF",
    registro_validacao."millisInsercao",
    COALESCE(registro_validacao."qtdAssuntos", 0) AS "qtdAssuntos",
    COALESCE(registro_validacao."qtdAssuntosFalha", 0) AS "qtdAssuntosFalha",
    COALESCE(registro_validacao."qtdMovimentos", 0) AS "qtdMovimentos",
    COALESCE(registro_validacao."qtdMovimentosFalha", 0) AS "qtdMovimentosFalha",
    COALESCE(registro_validacao."qtdRegras", 0) AS "qtdRegras",
    COALESCE(registro_validacao."qtdRegrasFalha", 0) AS "qtdRegrasFalha",
    registro_validacao."siglaTribunal",
    registro_validacao."esferaJustica",
    registro_validacao.grau,
    (((registro_validacao."qtdRegras" - registro_validacao."qtdRegrasFalha"))::numeric / (registro_validacao."qtdRegras")::numeric) AS taxaconformidade
   FROM public.registro_validacao
  WHERE ((registro_validacao."anoProcesso" > 1900) AND (registro_validacao."anoProcesso" <= 2020) AND (registro_validacao."geoLatitudeOrgao" IS NOT NULL));


ALTER TABLE public.vw_registro_validacao OWNER TO postgres;

--
-- Name: vwm_validacao_ano; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.vwm_validacao_ano AS
 SELECT vw_registro_validacao."anoProcesso",
    vw_registro_validacao."geoNomeMunicipio",
    vw_registro_validacao."geoUF",
    vw_registro_validacao."siglaTribunal",
    vw_registro_validacao."esferaJustica",
    count(vw_registro_validacao."dadosBasicos.numero") AS "qtdProcessos",
    (((sum(vw_registro_validacao."qtdRegras"))::numeric - (sum(vw_registro_validacao."qtdRegrasFalha"))::numeric) / (NULLIF(sum(vw_registro_validacao."qtdRegras"), 0))::numeric) AS "taxaConformidade",
    sum(vw_registro_validacao."qtdRegrasFalha") AS "qtdRegrasFalha",
    sum(vw_registro_validacao."qtdMovimentos") AS "qtdMovimentos",
    sum(vw_registro_validacao."qtdMovimentosFalha") AS "qtdMovimentosFalha",
    sum(vw_registro_validacao."qtdAssuntos") AS "qtdAssuntos",
    sum(vw_registro_validacao."qtdAssuntosFalha") AS "qtdAssuntosFalha",
    (((sum(vw_registro_validacao."qtdMovimentos"))::numeric - (sum(vw_registro_validacao."qtdMovimentosFalha"))::numeric) / (NULLIF(sum(vw_registro_validacao."qtdMovimentos"), 0))::numeric) AS "taxaConformidadeMovimentos",
    (((sum(vw_registro_validacao."qtdAssuntos"))::numeric - (sum(vw_registro_validacao."qtdAssuntosFalha"))::numeric) / (NULLIF(sum(vw_registro_validacao."qtdAssuntos"), 0))::numeric) AS "taxaConformidadeAssuntos"
   FROM public.vw_registro_validacao
  GROUP BY vw_registro_validacao."anoProcesso", vw_registro_validacao."geoNomeMunicipio", vw_registro_validacao."geoUF", vw_registro_validacao."siglaTribunal", vw_registro_validacao."esferaJustica"
  WITH NO DATA;


ALTER TABLE public.vwm_validacao_ano OWNER TO postgres;

--
-- Name: vwm_validacao_orgao; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.vwm_validacao_orgao AS
 SELECT vw_registro_validacao."dadosBasicos.orgaoJulgador.codigoOrgao",
    vw_registro_validacao."dadosBasicos.orgaoJulgador.nomeOrgao",
    vw_registro_validacao."geoLatitudeOrgao",
    vw_registro_validacao."geoLongitudeOrgao",
    vw_registro_validacao."geoNomeMunicipio",
    vw_registro_validacao."geoUF",
    vw_registro_validacao."siglaTribunal",
    vw_registro_validacao."esferaJustica",
    count(vw_registro_validacao."dadosBasicos.numero") AS "qtdProcessos",
    (((sum(vw_registro_validacao."qtdRegras"))::numeric - (sum(vw_registro_validacao."qtdRegrasFalha"))::numeric) / (NULLIF(sum(vw_registro_validacao."qtdRegras"), 0))::numeric) AS "taxaConformidade",
    sum(vw_registro_validacao."qtdRegrasFalha") AS "qtdRegrasFalha",
    sum(vw_registro_validacao."qtdMovimentos") AS "qtdMovimentos",
    sum(vw_registro_validacao."qtdMovimentosFalha") AS "qtdMovimentosFalha",
    sum(vw_registro_validacao."qtdAssuntos") AS "qtdAssuntos",
    sum(vw_registro_validacao."qtdAssuntosFalha") AS "qtdAssuntosFalha",
    (((sum(vw_registro_validacao."qtdMovimentos"))::numeric - (sum(vw_registro_validacao."qtdMovimentosFalha"))::numeric) / (NULLIF(sum(vw_registro_validacao."qtdMovimentos"), 0))::numeric) AS "taxaConformidadeMovimentos",
    (((sum(vw_registro_validacao."qtdAssuntos"))::numeric - (sum(vw_registro_validacao."qtdAssuntosFalha"))::numeric) / (NULLIF(sum(vw_registro_validacao."qtdAssuntos"), 0))::numeric) AS "taxaConformidadeAssuntos"
   FROM public.vw_registro_validacao
  GROUP BY vw_registro_validacao."dadosBasicos.orgaoJulgador.codigoOrgao", vw_registro_validacao."dadosBasicos.orgaoJulgador.nomeOrgao", vw_registro_validacao."geoLatitudeOrgao", vw_registro_validacao."geoLongitudeOrgao", vw_registro_validacao."geoNomeMunicipio", vw_registro_validacao."geoUF", vw_registro_validacao."siglaTribunal", vw_registro_validacao."esferaJustica"
  WITH NO DATA;


ALTER TABLE public.vwm_validacao_orgao OWNER TO postgres;

--
-- Name: regras regras_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regras
    ADD CONSTRAINT regras_pkey PRIMARY KEY (uid);


--
-- Name: idx_ano; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ano ON public.registro_validacao USING btree ("anoProcesso");


--
-- Name: idx_uf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_uf ON public.registro_validacao USING btree ("geoUF");


--
-- Name: idx_vwm_processos_orgao; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_vwm_processos_orgao ON public.vwm_validacao_orgao USING btree ("dadosBasicos.orgaoJulgador.codigoOrgao", "dadosBasicos.orgaoJulgador.nomeOrgao", "geoLatitudeOrgao", "geoLongitudeOrgao", "geoNomeMunicipio", "geoUF", "siglaTribunal", "esferaJustica");


--
-- PostgreSQL database dump complete
--

