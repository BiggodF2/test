
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



void WardBRDF(  Material mat,
				DirLight L,
				float3	position,//����λ��
				float3	normal,
				float3	toEye,//"����->��"���� 
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular)
{
	ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);
	////���㵽��
	float3 viewDirection = normalize(toEye);
	//Roughness in Brush Direction
	float _AlphaX = 1.0;
	float _AlphaY = 0.1;//Roughness in Brush Direction�ֳ��ȷ���ˢ
	//////�����е�����
	float3 T = normalize(cross(normal,toEye));	
	//////������շ��򣺶���->��Դ
	float3 vertexToLightSource = L.dir;
	////	
	//////��ľ���
	float distance = length(L.dir);
	//float attenuation = 1.0/distance;
	float3 lightDirection = normalize(vertexToLightSource);

	//���
	float3	halfwayVector = normalize(lightDirection + toEye);

	float3 	binormalDirection = cross(normal,T);

	float dotLN = dot(lightDirection, normal);
	ambient = L.ambient * mat.diffuse;
	diffuse = L.ambient*mat.diffuse*max(0.0, dotLN);
	if(dotLN > 0.0)
	{
		float dotHN = dot(halfwayVector,normal);
		float dotVN = dot(toEye, normal);
		float dotHTAlphaX = 
		dot(halfwayVector, T )/ _AlphaX;
		float dotHBAlphaY = 
		dot(halfwayVector,binormalDirection)/ _AlphaY;
		specular = mat.specular
		*sqrt(max(0.0, dotLN/dotVN))
		*exp(-2.0*(dotHTAlphaX*dotHTAlphaX
		+dotHBAlphaY*dotHBAlphaY)/(1.0 + dotHN));
	}
}


