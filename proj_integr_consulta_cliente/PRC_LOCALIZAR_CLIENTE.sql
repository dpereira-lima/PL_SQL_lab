create or replace procedure prc_localizar_cliente(nm_login_p varchar2, nr_cpf_p varchar2) is

l_target_url       varchar2(200);
req_http           utl_http.req;
resp_http          utl_http.resp;
body_l             clob;

begin

    delete from w_pessoa_fisica_loc
    where nm_usuario = nm_usuario_p;

    delete from w_pessoa_integracao;

    body_l := '{"nm_login": "'|| nm_login_p ||'",
                "cpf": "'|| nr_cpf_p ||'" }';

    l_target_url := 'http://10.65.238.62:2121/cadastro-ensemble/';

    req_http:= utl_http.begin_request(l_target_url, 'POST', 'HTTP/1.1');
    utl_http.set_header(req_http, 'Content-Type', 'application/json');
    utl_http.set_header(req_http, 'Content-Length', length(to_char(body_l)));
    utl_http.write_text(req_http, body_l);
    resp_http:= utl_http.get_response(req_http);
    utl_http.end_response(resp_http);

    exception
        when others then
            dbms_output.put_line('Erro: ' || sqlerrm);
            utl_http.end_response(resp_http);

end;
/