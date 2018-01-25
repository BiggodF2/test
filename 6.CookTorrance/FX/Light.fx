
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


void CookTorrance(Material mat,
				DirLight l,  
				float3 position,
				float3 normal,
				float3 toEye,//"����->��"����  
				out float4 ambient,
				out float4 diffuse, 
				out float4 specular)  
{  
    //��ʼ��  
    ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    specular = float4(0.0f, 0.0f, 0.0f, 0.0f);  
  
    float3 P = position.xyz;  
    float3 N = normal.xyz;  
  
  
    //���շ������Դ�����෴  
    float3 lightVec = -l.dir;  
    float3 L = normalize(lightVec);  
    //����������ֵ  
    ambient = mat.ambient*l.ambient;  
  
  
    float nl = max(dot(L, N), 0);  
    //����������  
    diffuse = nl * mat.diffuse * l.diffuse;  
      
    // Cook-Torrance ����ģ����Ⱦ  
    float3 V = toEye;  
    float3 H = normalize(L + V);  
  
    float nv = dot(N, V);  
    if (nv > 0 && nl > 0)  
    {  
        float nh = dot(N, H);  
        float m = 0.3;  
        float temp = (nh*nh - 1) / (m*m*nh*nh);  
        float roughness = (exp(temp)) / (pow(m, 2)*pow(nh, 4));//�ֲڶȣ����� beckmann ����  
  
        float vh = dot(V, H);  
        float a = (2 * nh*nv) / vh;  
        float b = (2 * nh*nl) / vh;  
        float geometric = min(a, b);  
        geometric = min(1, geometric);//����˥��ϵ��  
  
        float f = 0.125;  
        float fresnelCoe = f + (1 - f)*pow(1 - vh, 5);////fresnel ����ϵ��  
        float rs = (fresnelCoe*roughness*geometric) / (nv*nl);  
        specular = rs * nl * mat.specular * l.specular;  
    }  
}
