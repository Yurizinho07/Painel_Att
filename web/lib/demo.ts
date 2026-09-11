import type {Data} from "./types";
const id=(n:number)=>`00000000-0000-4000-8000-${String(n).padStart(12,"0")}`;
const date=new Intl.DateTimeFormat("en-CA",{timeZone:"America/Sao_Paulo",year:"numeric",month:"2-digit",day:"2-digit"}).format(new Date());
export const demoData:Data={
 patients:["Marina Oliveira","Lucas Ferreira","Helena Costa","Pedro Almeida","Clara Santos","Rafael Lima"].map((name,i)=>({id:id(i+1),name,age:[29,12,35,24,18,42][i],status:["Aguardando contato","Triagem agendada","Aguardando vaga","Em atendimento","Em atendimento","Encerrado"][i],availability:[`${["Segunda","Terça","Quarta"][i%3]} - ${i%2?"tarde":"manhã"}`],details:{phone:"(51) 90000-0000",email:"exemplo@example.com",income:2800,members:3,atitus_student:false,employee:false,psychology_relative:false,guardian:i===1?"Responsável fictício":"",reason:"Exemplo fictício para apresentação",observer:"Sim"}})),
 students:["Ana Martins","Bruno Rocha","Camila Souza","Daniel Nunes"].map((name,i)=>({id:id(i+20),name,supervisor:["Mariana Ungaretti","Francielle Beria","Fernanda Cerutti","Vera Ramires"][i],semester:i%2?"Clínico 2":"Clínico 1",availability:["Segunda - 09h","Segunda - 10h","Terça - 14h","Quarta - 09h"],institution_verified:true,declared_count:0,reconciled:true})),
 assignments:[{id:id(40),patient_id:id(4),student_id:id(20),started_on:date,ended_on:null,reason:""},{id:id(41),patient_id:id(5),student_id:id(20),started_on:date,ended_on:null,reason:""}],
 appointments:[9,10,14].map((h,i)=>({id:id(50+i),patient_id:id(i+1),student_id:id(i+20),start:`${date}T${h.toString().padStart(2,"0")}:00:00-03:00`,end:`${date}T${h.toString().padStart(2,"0")}:50:00-03:00`,kind:i===2?"Sessão":"Triagem",status:"Agendado",room:"Sala 1"}))
};
