
//ƽ�й�
struct DirLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	unused;		//��4D������������
};

//���Դ
struct PointLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	pos;		//��Դλ��
	float	range;		//��Դ���䷶Χ

	float3	att;		//��ǿ˥��ϵ��
	float	unused;		//"4D����"������
};

//�۹��
struct SpotLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	range;		//���䷶Χ

	float3	pos;		//λ��
	float	spot;		//�۹�ǿ��ϵ��

	float3	att;		//���ϵ��
	float	theta;		//���ɢ�Ƕ�
};

//����
struct Material
{
	float4	ambient;
	float4	diffuse;
	float4	specular;	//specular�е�4��Ԫ�ش�����ʵı���⻬�̶�
};


void AhikhminDirctionLight(  Material mat,
				DirLight L,
				float3	position,//����λ��
				float3	normal,
				float3	toEye,//"����->��"����
				float3 eyePos,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular
				)
{

	//��ʼ��  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);
	//������շ��򣺶���->��Դ
	float3 vertexToLightSource = L.dir;
	//��һ�����߷���
	float3 lightDirection = normalize(vertexToLightSource);//vertexToLightSource
	float pi = 3.1415926535;
	ambient = mat.ambient * L.ambient;
	float Nu = 10;
	float Nv = 10000;
	float3 tangent  =  normalize( cross( normal, toEye ) );
	float3 bitangent = normalize( cross( normal, tangent) );
	float3 H = normalize(toEye + lightDirection);
	float dotNL = max(dot(normal,lightDirection),0.0);
	float dotNV = max(dot(normal,toEye),0.0);
	float HdotN = max(dot(normal,H),0.0);
	float dotVH = max(dot(toEye,H),0.0);
	float HdotL = max(dot(H,lightDirection),0.0);
	float HdotB = dot(H, bitangent);
	float HdotT = dot(H, tangent);
	if(dotNL > 0.0)
	{
	diffuse = (28.0*mat.diffuse) / (23.0*pi)
		*(1.0-mat.specular)
		*(1.0 -pow(1.0-dotNV/2.0,5.0))
		*(1.0 -pow(1.0-dotNL/2.0,5.0));
	
	float f = 10.0;  //���ݲ��ʲ�ͬf��ͬ
    float4 fresnelCoe = mat.specular + (1 - mat.specular)*pow(1.0 - HdotL, 5.0);////fresnel ����ϵ��  
	
	float ps_num_exp = Nu * HdotT * HdotT + Nv * HdotB * HdotB;
	ps_num_exp /= (1.0 - HdotN * HdotN);

	float Ps_num = sqrt((HdotN + 1) * (Nv + 1));
	Ps_num *= pow(HdotN, ps_num_exp);

	float Ps_den = 8.0 * 3.14159 * HdotL;
	Ps_den *= max(HdotL, HdotL);

	specular = (Ps_num / Ps_den);
	specular *= (mat.specular + (1.0 - mat.specular) * pow(1.0 - HdotL, 5.0));
	}
	
}
